# int_scratch

A personal scratch repository for interview prep and coding practice — Python, SQL, and data science.

---

## Structure

```
int_scratch/
├── python/
│   ├── algorithms/        # sorting, searching, recursion, etc.
│   ├── data_structures/   # arrays, trees, graphs, hashmaps, etc.
│   └── ds_ml/             # pandas, numpy, sklearn, EDA, modeling
└── sql/
    ├── window_functions/
    ├── aggregations/
    └── joins/
```

---

## Environment Setup

Requires [Miniconda](https://docs.conda.io/en/latest/miniconda.html).

**Create the environment:**
```bash
make create-env
```

This will:
- Create a conda environment named `scr-int` with Python 3.13
- Install all dependencies from `requirements.txt`
- Register the Jupyter kernel for use in Cursor/JupyterLab

**Remove the environment:**
```bash
make remove-env
```

**Activate manually:**
```bash
conda activate scr-int
```

---

## Stack

| Category | Tools |
|---|---|
| Language | Python 3.13 |
| Data | pandas, numpy, scipy |
| ML | scikit-learn |
| Visualization | matplotlib, seaborn |
| Notebooks | JupyterLab, ipykernel |
| SQL Linting | sqlfluff (dialect: ansi) |
| Python Linting | Ruff |
| Testing | pytest |

---

## Config Files

| File | Purpose |
|---|---|
| `pyproject.toml` | Ruff linting and formatting rules |
| `.sqlfluff` | SQLFluff dialect and style rules |
| `.gitignore` | Excludes caches, checkpoints, data files |
| `Makefile` | Environment management commands |
| `requirements.txt` | Pinned top-level dependencies |