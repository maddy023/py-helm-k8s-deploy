
# Makefile for Python application with virtual environment, linting, testing, and Docker support.
.PHONY: help init install test lint format build run-docker clean env leave

# Variables
VENV = venv
PYTHON = $(VENV)/bin/python3
PIP = $(VENV)/bin/pip
VENV_PATH = $(VENV)/bin/activate
ENV_FILE = .env
DOCKER_NAME = py-pub
DOCKER_TAG = local

# Command Descriptions
define PRINT_HELP_PYSCRIPT
import re, sys
for line in sys.stdin:
    match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
    if match:
        target, help = match.groups()
        print(f'{target:20} {help}')
endef
export PRINT_HELP_PYSCRIPT

# Default Target
help: ## Show this help message
	@python3 -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

init: ## Set up virtual environment and install requirements
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

install: ## Install development dependencies
	$(PIP) install -r requirements.txt

test: ## Run tests with pytest
	$(PYTHON) -m pytest -p no:logging -p no:warnings

lint: ## Lint code with flake8
	pylint ./src

format: ## Format code with autopep8
	autopep8 --in-place --recursive ./src

build: ## Build Docker image
	docker build -t $(DOCKER_NAME):$(DOCKER_TAG) .

run-docker:
	docker run -it -p 80:80 $(DOCKER_NAME):$(DOCKER_TAG)

clean: ## Clean up cache, pyc, and build files
	rm -rf *.egg-info build dist .pytest_cache
	find . -type d -name "__pycache__" | xargs rm -rf
	rm -rf $(VENV)

env: $(VENV_PATH) ## Source venv and environment files
	source $(VENV_PATH) && source $(ENV_FILE)

leave: clean ## Deactivate and clean up venv
	deactivate


