import math
import logging

logger = logging.getLogger("contest2025.test_cases.config")


def pre_config(meta: dict) -> dict:
    if "emit" not in meta:
        raise ValueError("No emit type specified in metadata")
    if meta["emit"] == "asm":
        ext = "s"
    elif meta["emit"] == "llvm":
        ext = "ll"
    elif meta["emit"] == "bc":
        ext = "bc"
    else:
        raise ValueError(f"Unknown emit type: {meta['emit']}. Available: asm, llvm, bc")

    return {"variables": {"ext": ext}}


atanh_half = math.atanh(0.5)


def compress(x: float) -> float:
    return math.tanh(atanh_half * x)


"""
Scoring:

basic (50)
- tyck -- 15
- codegen -- 35

optional (max 50)
- generic -- 20 -- 15 baseline
- struct -- 15 -- 10 baseline
- enum -- 15 -- 10 baseline
  - mixed(generic,struct,enum) -- 15
- codegen_asm -- 20

performance (200)
- size -- 50
- speed -- 150
"""


def score_portion(d: dict[str, float]) -> float:
    if len(d) == 0:
        return 0.0
    return sum(d.values()) / len(d)


def compress_score_portion(d: dict[str, float]) -> float:
    if len(d) == 0:
        return 0.0
    return sum(compress(v) for v in d.values()) / len(d)


def gen_score(scores: dict[str, dict[str, float]]) -> dict:
    codegen_score = score_portion(scores.get("codegen", {})) * 35
    tyck_score = score_portion(scores.get("tyck", {})) * 15
    generic_only_score = score_portion(scores.get("optional-generic-only", {})) * 15
    struct_only_score = score_portion(scores.get("optional-struct-only", {})) * 10
    enum_only_score = score_portion(scores.get("optional-enum-only", {})) * 10
    mixed_score = score_portion(scores.get("optional-mixed", {})) * 15
    codegen_asm_score = score_portion(scores.get("optional-asm", {})) * 20

    speed_score = compress_score_portion(scores.get("speed", {})) * 150
    # Since we don't test the output of size, we assign them from the result of speed
    orig_speed_scores = scores.get("speed", {})
    orig_size_scores = scores.get("size", {})
    size_score_before = {}
    for k in orig_size_scores.keys():
        if (
            k not in orig_speed_scores
            or orig_speed_scores[k] is None
            or orig_speed_scores[k] <= 0
        ):
            size_score_before[k] = 0.0
        else:
            size_score_before[k] = orig_size_scores[k]
    size_score = compress_score_portion(size_score_before) * 50

    optional_score = min(
        50,
        generic_only_score
        + struct_only_score
        + enum_only_score
        + mixed_score
        + codegen_asm_score,
    )

    overall_score = (
        codegen_score + tyck_score + optional_score + size_score + speed_score
    )

    # Other parts are TBD
    return {
        "test_cases": scores,
        "sections": {
            "codegen": codegen_score,
            "tyck": tyck_score,
            "optional": optional_score,
            "optional-generic-only": generic_only_score,
            "optional-struct-only": struct_only_score,
            "optional-enum-only": enum_only_score,
            "optional-mixed": mixed_score,
            "optional-asm": codegen_asm_score,
            "size": size_score,
            "speed": speed_score,
            "score": overall_score,
        },
        "overall_score": overall_score,
    }
