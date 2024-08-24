# Step 1: Base image
FROM node:18-alpine as base

# Step 2: Set the working directory
WORKDIR /app

# Step 3: Install system dependencies
RUN apk add --no-cache git python3 make g++ curl

# Step 4: Clone the forked repository and switch to the stable branch
RUN git clone https://github.com/blueprintkey/AFFiNE.git .
RUN git checkout stable

# Step 5: Install application dependencies
RUN npm install

# Step 6: Build the application
RUN npm run build

# Step 7: Final stage to run the application
FROM node:18-alpine as final

# Step 8: Set the working directory
WORKDIR /app

# Step 9: Copy the built application from the base stage
COPY --from=base /app /app

# Step 10: Expose necessary ports
EXPOSE 3010
EXPOSE 5555

# Step 11: Set environment variables
ENV NODE_ENV=production
ENV DATABASE_URL=postgres://affine:affine@postgres:5432/affine
ENV REDIS_SERVER_HOST=redis

# Step 12: Command to run the application
CMD ["sh", "-c", "node ./scripts/self-host-predeploy && node ./dist/index.js"]
