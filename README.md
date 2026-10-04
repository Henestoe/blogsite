# Flask Blog Deployment on AWS

A Flask blog containerized with Docker and deployed on an AWS EC2
instance, with automated testing and image publishing through
GitHub Actions.


## Project goal

Practice deploying and maintaining a web application using Docker,
GitHub Actions, AWS, and Nginx.

The application is based on the Flask tutorial. My work focused on
containerization, CI, server configuration, HTTPS, and deployment
automation.

## What I implemented

- A Docker image that runs the application as a non-root user.
- Persistent storage for the SQLite database using a Docker volume.
- GitHub Actions for automated tests and container image publishing.
- Commit-based image tags in GitHub Container Registry.
- An Ubuntu EC2 server running the application behind Nginx.
- HTTPS using Let's Encrypt and Certbot.
- A deployment script with health checks and automatic container rollback.

## How the workflow works

1. Code is pushed to GitHub.
2. GitHub Actions runs the application tests.
3. After successful tests on main, it builds and publishes the Docker image.
4. I manually run the deployment script on EC2 with the chosen image tag.
5. The script pulls the image, replaces the container, and checks the application.
6. If the new container fails to start or pass its health check,
   the script attempts to restore the previous container.

The current setup uses CI with manual deployment.

## Data persistence

The database and instance configuration are stored in a Docker volume
separate from the application container. Replacing the container
preserves the blog posts.

## Current limitations

- The application runs on one EC2 instance.
- Container replacement causes a brief interruption.
- Container rollback does not reverse database changes.

## Application source

The application is based on Flaskr from the Pallets Flask tutorial.
The upstream licence is retained in this repository.
