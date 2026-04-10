def jaccard_similarity(a: list, b: list) -> float:
    set_a, set_b = set(a), set(b)
    intersection = set_a & set_b
    union = set_a | set_b
    if not union:
        return 1.0
    return len(intersection) / len(union)


def extract_fields(theme: dict) -> dict:
    """Extract and group comparable fields from a theme dict."""
    asset_keys = [k for k in theme if k.startswith("asset_src_")]
    ext_keys   = [k for k in theme if k.startswith("extension_metafield_")]
    return {
        "name":       theme.get("name", "").lower().split(),
        "content":    theme.get("content", "").lower().split(),
        "assets":     [theme[k] for k in sorted(asset_keys)],
        "extensions": [theme[k] for k in sorted(ext_keys)],
    }


FIELD_WEIGHTS = {
    "name":       0.10,
    "content":    0.35,
    "assets":     0.35,
    "extensions": 0.20,
}

SIMILARITY_THRESHOLD = 0.5


def compare_themes(custom: dict, official: dict) -> dict:
    """Return per-field and weighted overall Jaccard similarity scores."""
    custom_fields   = extract_fields(custom)
    official_fields = extract_fields(official)

    per_field = {
        field: jaccard_similarity(custom_fields[field], official_fields[field])
        for field in FIELD_WEIGHTS
    }

    overall = sum(score * FIELD_WEIGHTS[field] for field, score in per_field.items())

    return {
        "custom_id":       custom["id"],
        "custom_name":     custom["name"],
        "custom_dev":      custom["developer"],
        "official_id":     official["id"],
        "official_name":   official["name"],
        "official_dev":    official["developer"],
        "per_field":       {k: round(v, 3) for k, v in per_field.items()},
        "overall":         round(overall, 3),
        "flag_for_review": overall >= SIMILARITY_THRESHOLD,
    }


def detect_piracy(custom_themes: list[dict], official_themes: list[dict]) -> list[dict]:
    """
    Compare every custom theme against every official theme.
    Returns results sorted by overall similarity descending.
    """
    results = [
        compare_themes(custom, official)
        for custom   in custom_themes
        for official in official_themes
    ]
    return sorted(results, key=lambda r: r["overall"], reverse=True)


# ---------------------------------------------------------------------------
# Sample data
# ---------------------------------------------------------------------------

official_themes = [
    {
        "id": 1,
        "name": "Dawn",
        "developer": "Shopify",
        "content": "table style=background-color:#33475b",
        "asset_src_1": "Shopify Logo",
        "asset_src_2": "Dawn Logo",
        "asset_src_3": "Kitten",
        "extension_metafield_1": "Area:Product, Key:Avg_Rating",
        "extension_metafield_2": "Area:Product, Key:Combined_Listings",
    },
    {
        "id": 2,
        "name": "Dawn",
        "developer": "VeryGoodThemes",
        "content": "table style=background-color:#DFFF00",
        "asset_src_1": "Shopify Logo",
        "asset_src_2": "Chatreuse Logo",
        "asset_src_3": "Lizard",
        "extension_metafield_1": "Area:Product, Key:Subscriptions",
        "extension_metafield_2": "Area:Product, Key:Dynamic_Tiles",
    },
]

custom_themes = [
    {
        "id": 31,
        "name": "Dusk",
        "developer": "CheapThemes4Everz",
        "content": "table style=background-color:#33475b",
        "asset_src_1": "Shopify Logo",
        "asset_src_2": "Dawn Logo",
        "asset_src_3": "Puppy",
        "extension_metafield_1": "Area:Product, Key:Avg_Rating",
        "extension_metafield_2": "Area:Product, Key:Combined_Listings",
    },
    {
        "id": 15,
        "name": "Midnight",
        "developer": "VeryGoodThemes",
        "content": "table style=background-color:#E6E6FA",
        "asset_src_1": "Midnight Logo",
        "asset_src_2": "Cardigan Logo",
        "asset_src_3": "Cat",
        "extension_metafield_1": "Area:Product, Key:Magic_Sort",
        "extension_metafield_2": "Area:Product, Key:Semantic_Search",
    },
]

if __name__ == "__main__":
    results = detect_piracy(custom_themes, official_themes)
    for r in results:
        flag = "*** FLAG FOR REVIEW ***" if r["flag_for_review"] else "OK"
        print(
            f"[{flag}]\n"
            f"  Custom  : {r['custom_name']} (id={r['custom_id']}) by {r['custom_dev']}\n"
            f"  Official: {r['official_name']} (id={r['official_id']}) by {r['official_dev']}\n"
            f"  Scores  : {r['per_field']}\n"
            f"  Overall : {r['overall']}\n"
        )
