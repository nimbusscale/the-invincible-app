# The Invincible App
The Invincible App is a resilient cloud architecture distributed across DigitalOcean regions. It is designed with an Recovery Point Objective and Recovery Time Objective close to 0 seconds.

At the heart of the app is Node.js code deployed in Kubernetes clusters across two regions: Amsterdam and New York. The code accesses a PostgreSQL database with a primary and standby node in Amsterdam and a read-only node in New York.

# Architecture Diagram



When a user connects to the Invincible App, the request lands on a global load balancer configured to prioritize routing to New York. If New York is unavailable, the request is routed to Amsterdam.

The Node.js code for the Invincible App is universal for both locations, with database connection strings and credentials passed as environment variables.

# Questions
