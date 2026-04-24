#!/usr/bin/env python3
"""Submit a prompt to ComfyUI z-image-turbo workflow and wait for result."""

import json
import sys
import time
import urllib.request
import urllib.error
import random

COMFY_URL = "http://127.0.0.1:8188"

# Flattened API-format workflow derived from image_z_image_turbo.json
def build_prompt(text: str, width: int = 1024, height: int = 1024, steps: int = 6, seed: int = None) -> dict:
    if seed is None:
        seed = random.randint(0, 2**32 - 1)
    return {
        "30": {
            "class_type": "CLIPLoader",
            "inputs": {
                "clip_name": "qwen_3_4b.safetensors",
                "type": "lumina2",
                "device": "default"
            }
        },
        "29": {
            "class_type": "VAELoader",
            "inputs": {"vae_name": "ae.safetensors"}
        },
        "28": {
            "class_type": "UNETLoader",
            "inputs": {
                "unet_name": "z_image_turbo_bf16.safetensors",
                "weight_dtype": "default"
            }
        },
        "27": {
            "class_type": "CLIPTextEncode",
            "inputs": {"clip": ["30", 0], "text": text}
        },
        "13": {
            "class_type": "EmptySD3LatentImage",
            "inputs": {"width": width, "height": height, "batch_size": 1}
        },
        "11": {
            "class_type": "ModelSamplingAuraFlow",
            "inputs": {"model": ["28", 0], "shift": 3}
        },
        "33": {
            "class_type": "ConditioningZeroOut",
            "inputs": {"conditioning": ["27", 0]}
        },
        "3": {
            "class_type": "KSampler",
            "inputs": {
                "model": ["11", 0],
                "positive": ["27", 0],
                "negative": ["33", 0],
                "latent_image": ["13", 0],
                "seed": seed,
                "steps": steps,
                "cfg": 1,
                "sampler_name": "res_multistep",
                "scheduler": "simple",
                "denoise": 1
            }
        },
        "8": {
            "class_type": "VAEDecode",
            "inputs": {"samples": ["3", 0], "vae": ["29", 0]}
        },
        "9": {
            "class_type": "SaveImage",
            "inputs": {"images": ["8", 0], "filename_prefix": "tower_gen"}
        }
    }


def post_json(url: str, data: dict) -> dict:
    body = json.dumps(data).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())


def get_json(url: str) -> dict:
    with urllib.request.urlopen(url) as r:
        return json.loads(r.read())


def queue_prompt(prompt: dict) -> str:
    resp = post_json(f"{COMFY_URL}/prompt", {"prompt": prompt})
    return resp["prompt_id"]


def wait_for_result(prompt_id: str, timeout: int = 300) -> dict:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            history = get_json(f"{COMFY_URL}/history/{prompt_id}")
            if prompt_id in history:
                return history[prompt_id]
        except Exception:
            pass
        time.sleep(2)
    raise TimeoutError(f"Generation timed out after {timeout}s")


def extract_image_paths(result: dict) -> list[str]:
    paths = []
    for node_output in result.get("outputs", {}).values():
        for img in node_output.get("images", []):
            paths.append(img["filename"])
    return paths


def main():
    prompt_text = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else DEFAULT_PROMPT

    print(f"Prompt: {prompt_text[:80]}...")
    print("Submitting to ComfyUI...")

    prompt = build_prompt(prompt_text)
    prompt_id = queue_prompt(prompt)
    print(f"Queued: {prompt_id}")
    print("Waiting for generation", end="", flush=True)

    while True:
        try:
            history = get_json(f"{COMFY_URL}/history/{prompt_id}")
            if prompt_id in history:
                result = history[prompt_id]
                print()
                filenames = extract_image_paths(result)
                if filenames:
                    output_dir = "/Users/wangyiwen/comfy/ComfyUI/output"
                    print("Generated images:")
                    for f in filenames:
                        print(f"  {output_dir}/{f}")
                else:
                    print("Done (no image filenames found in output)")
                    print(json.dumps(result.get("outputs", {}), indent=2))
                return
        except Exception:
            pass
        print(".", end="", flush=True)
        time.sleep(2)


PROMPTS = [
    # v1: flat icon approach
    (
        "flat 2D game icon, top-down tower defense sprite, viewed from directly above, "
        "completely flat like a floor tile or stamp, zero height, no 3D, no perspective, "
        "square frame design with hollow center, "
        "alien tech style, deep purple body, glowing cyan teal edges, orange corner nodes, "
        "cartoon cel-shaded, bold clean outlines, transparent background, centered"
    ),
    # v2: map marker / symbol approach
    (
        "top-down map marker, military strategy game unit icon, "
        "flat 2D symbol viewed from straight above, like a chess piece seen from a drone, "
        "square hollow frame tower base, completely flat silhouette, "
        "purple and teal alien technology colors, glowing neon cyan borders, orange accents, "
        "cartoon style, clean vector-like, transparent background, no shadow, centered"
    ),
    # v3: emblem / badge approach
    (
        "game tower icon badge, emblem design, top-down view only, flat 2D, "
        "square frame with hollow interior, interlocking rectangular borders, "
        "alien sci-fi aesthetic, vibrant purple chassis, electric cyan glowing lines, "
        "orange energy nodes at corners, cel-shaded cartoon, "
        "bold outlines, transparent background, centered composition, no depth no shadow"
    ),
    # v4: explicit flat graphic design
    (
        "flat graphic design, 2D game asset, top-down orthographic, "
        "looks like a board game tile seen from above, zero elevation, "
        "square border frame, thick lines, hollow center, "
        "alien purple metallic texture, teal cyan glowing trim, bright orange studs, "
        "cartoon colorful, crisp edges, white or transparent background"
    ),
]

DEFAULT_PROMPT = PROMPTS[0]

if __name__ == "__main__":
    main()
