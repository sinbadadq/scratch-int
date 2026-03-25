ENV_NAME = scr-int
PYTHON_VERSION = 3.13

create-env:
	conda create -n $(ENV_NAME) python=$(PYTHON_VERSION) -y
	conda run -n $(ENV_NAME) pip install -r requirements.txt
	conda run -n $(ENV_NAME) python -m ipykernel install --user --name $(ENV_NAME) --display-name "Python ($(ENV_NAME))"
	@echo "Environment $(ENV_NAME) created and kernel registered."

remove-env:
	conda env remove -n $(ENV_NAME) -y
	jupyter kernelspec remove $(ENV_NAME) -f
	@echo "Environment $(ENV_NAME) and kernel removed."

.PHONY: create-env remove-env