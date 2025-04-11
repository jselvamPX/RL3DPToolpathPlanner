where?=platform
project_name?=rl3dptoolpathplanner
persistent_env_name?=persistent_env
persistent_env_path?=~/.conda-envs/$(persistent_env_name)

install-base-dependencies:
	./scripts/install-base-dependencies.sh $(persistent_env_name) $(persistent_env_path)
	@$(MAKE) register-ipykernel

register-ipykernel:
	@uv run ipython kernel install --user --env VIRTUAL_ENV $(pwd)/.venv --env CUDA_PATH $(persistent_env_path) --name=pxtopopt

setup-artifactory-creds:
	./scripts/setup-artifactory.sh 

help:               ## Show the help.
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@fgrep "##" Makefile | fgrep -v fgrep

install-uv:
	curl -LsSf https://astral.sh/uv/install.sh | sh

configure-envs:
	@conda create --force -n $(persistent_env_name) python=3.11 -y
	@if [ ! -d ".venv" ]; then \
		python3.11 -m venv .venv; \
		echo "Virtual environment created!"; \
	else \
		echo "Virtual environment already exists."; \
	fi
	@$(MAKE) install-base-dependencies

install-for-pat-token: configure-envs ## Install the project in editable mode with test libs.
	@if [ "$(where)" != "ml2" ] && [ "$(where)" != "platform" ]; then \
		echo "where must be either ml2, platform or ci (got $(where))."; \
		exit 1; \
	fi
	@uv sync --inexact --only-dev
	@. .venv/bin/activate && flux install -e libraries/toolpath_manager
	@. .venv/bin/activate && flux install -e libraries/pxtopopt[$(where)]

install: install-without-conda ## Install the project in editable mode. Remove `dask-expr` due to weird bug.
	@$(MAKE) configure-envs

install-without-conda: ## Install the project in editable mode.
	@if [ "$(where)" != "ml2" ] && [ "$(where)" != "platform" ]; then \
		echo "where must be either ml2, platform or ci (got $(where))."; \
		exit 1; \
	fi
	@uv sync --all-packages --no-dev --extra $(where)

install-dev: ## Install the project in editable mode with test libs.
	@if [ "$(where)" != "ml2" ] && [ "$(where)" != "platform" ]; then \
		echo "where must be either ml2, platform or ci (got $(where))."; \
		exit 1; \
	fi
	@uv sync --all-packages --extra $(where)
	@$(MAKE) configure-envs
	@cd applications/printability-checker/src/printability_checker/frontend && npm install

upgrade: ## Upgrade all packages to the latest version.
	@if [ "$(where)" != "ml2" ] && [ "$(where)" != "platform" ]; then \
		echo "where must be either ml2, platform or ci (got $(where))."; \
		exit 1; \
	fi
	@uv sync --all-packages --upgrade --extra $(where)

install-ci: setup-artifactory-creds ## Install the project in editable mode with test libs.
	## Add frozen flag to become more strict with dependency versioning
	@uv sync --all-packages
	@$(MAKE) configure-envs

install-ci-with-req-dump: setup-artifactory-creds ## Install the project in editable mode with test libs, but dumping non-test reqs to file.
	## Add frozen flag to become more strict with dependency versioning
	@uv sync --all-packages --no-dev
	@uv pip freeze > requirements-all.txt
	@uv sync --all-packages
	@$(MAKE) configure-envs

lint:               ## Run black, isort, mypy, and other code checks.
	@uv run ruff check --fix
	@uv run ruff format .
	@uv run mypy --config-file=./pyproject.toml ./libraries
	@uv run nbstripout notebooks/** twenty/** 

lint-check:         ## Run black, isort, mypy, and other code checks, without applying any changes.
	@uv run ruff check
	@uv run ruff format . --check
	@uv run mypy --config-file=./pyproject.toml ./libraries
	@uv run nbstripout --verify notebooks/** twenty/**

test:      	    ## Run tests and generate coverage report.
	@uv run pytest -v -m "not pxtopopt" --cov=./libraries -l --tb=short --cov-report term-missing ./tests

test-run-topopt:
	@export PYVISTA_OFF_SCREEN=true && \
	cd twenty && uv run jupyter nbconvert --to python run_topopt.ipynb --stdout | uv run python
	@-pgrep -f "simulate_surface" > /dev/null && pkill -f "simulate_surface"

clean:              ## Clean unused/cache files.
	@find . -depth -type d -empty -delete
	@rm -rf .cache
	@rm -rf .pytest_cache
	@rm -rf .mypy_cache
	@rm -rf .ruff_cache
	@rm -rf build
	@rm -rf dist
	@rm -rf *.egg-info
	@rm -rf **/*.egg-info
	@rm -rf .ipynb_checkpoints
	@rm -rf **/.ipynb_checkpoints
	@rm -rf htmlcov
	@rm -rf .tox/
	@rm -rf docs/build
	@rm -rf .coverage
	@rm -rf coverage.xml
	@find . -name '*.pyc' -exec rm -f {} \;
	@find . -name '__pycache__' -prune -exec rm -rf {} \;
	@find . -name 'Thumbs.db' -exec rm -f {} \;
	@find . -name '*~' -exec rm -f {} \;

clean-venv: ## Clean the virtual environment.
	@rm -rf .venv
	@rm -rf $(persistent_env_path)

dash-printability-checker:  # start ReactJS server and load the printability checker dashboard.
	@cd applications/printability-checker/src/printability_checker/frontend && npm run dev & \
	cd applications/printability-checker/src/printability_checker && uv run streamlit run dashboard.py

docker-build:
	@docker build . -f applications/printability-checker/Dockerfile -t printability-checker

check-kedro-registry:
	@uv run kedro registry list