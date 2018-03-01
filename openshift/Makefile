build:
		docker build . -t fabri8-analytics-deploy-image

bash: build
		docker run --rm -ti fabri8-analytics-deploy-image bash

deploy: build
		docker run --rm -ti fabri8-analytics-deploy-image ./deploy.sh

clean-deploy: build
		docker run --rm -ti fabri8-analytics-deploy-image ./deploy.sh --purge-aws-resources

clean: build
		docker run --rm -ti fabri8-analytics-deploy-image ./cleanup.sh
