"""Fixed Maintainability Index calculation used by the quality matrix."""

import math


def maintainability_index(row):
    try:
        volume = max(1.0, float(row["H-volume"]))
        ccn = float(row["CCN"])
        nloc = max(1.0, float(row["NLOC"]))
    except (KeyError, TypeError, ValueError):
        return None
    raw = (
        100 * (171 - 5.2 * math.log(volume) - 0.23 * ccn - 16.2 * math.log(nloc)) / 171
    )
    return round(max(0.0, min(100.0, raw)), 2)
