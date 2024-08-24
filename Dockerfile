# Step 1: Base image
FROM node:18-alpine as base

# Step 2: Set the working directory
WORKDIR /app

# Step 3: Install system dependencies
RUN apk add --no-cache git python3 make g++ curl

# Step 4: Clone the forked repository and switch to the stable branch
RUN git clone https://github.com/blueprintkey/AFFiNE.git .
RUN git checkout stable

# Step 5: Remove any existing node_modules and package-lock.json to avoid conflicts
RUN rm -rf node_modules package-lock.json

# Step 6: Install application dependencies using npm ci to ensure clean install
RUN npm ci --legacy-peer-deps

# Step 7: Build the application
RUN npm run build

# Step 8: Final stage to run the application
FROM node:18-alpine as final

# Step 9: Set the working directory
WORKDIR /app

# Step 10: Copy the built application from the base stage
COPY --from=base /app /app

# Step 11: Expose necessary ports
EXPOSE 3010
EXPOSE 5555

# Step 12: Set environment variables
ENV NODE_ENV=production
ENV DATABASE_URL=postgres://affine:affine@postgres:5432/affine
ENV REDIS_SERVER_HOST=redis

# Step 13: Command to run the application
CMD ["sh", "-c", "node ./scripts/self-host-predeploy && node ./dist/index.js"]
