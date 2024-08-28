# Step 1: Use a smaller base image for building the application
FROM node:18-alpine AS build

# Step 2: Set the working directory
WORKDIR /app

# Step 3: Install system dependencies
RUN apk add --no-cache git python3 make g++ curl

# Step 4: Clone the forked repository and switch to the stable branch
RUN git clone https://github.com/blueprintkey/AFFiNE.git .
RUN git checkout stable

# Step 5: Copy the package.json and yarn.lock files
COPY package.json yarn.lock ./

# Step 6: Install application dependencies using Yarn with network timeout and cleaning up afterwards
RUN yarn install --network-timeout 100000 && \
    yarn cache clean && \
    rm -rf /tmp/* /var/tmp/* /usr/share/man /var/cache/apk/*

# Step 7: Set the BUILD_TYPE environment variable and build the application
ENV BUILD_TYPE=stable
RUN yarn build

# Step 8: Create a minimal production image
FROM node:18-alpine AS production

# Step 9: Set the working directory
WORKDIR /app

# Step 10: Copy the built application from the build stage
COPY --from=build /app /app

# Step 11: Install production dependencies using Yarn Workspaces Focus and clean up
RUN yarn workspaces focus --production --all && \
    yarn cache clean && \
    rm -rf /tmp/* /var/tmp/* /usr/share/man /var/cache/apk/*

# Step 12: Expose necessary ports
EXPOSE 3010
EXPOSE 5555

# Step 13: Set environment variables
ENV NODE_ENV=production
ENV DATABASE_URL=postgres://affine:affine@postgres:5432/affine
ENV REDIS_SERVER_HOST=redis

# Step 14: Add a health check (optional, customize as needed)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3010/health || exit 1

# Step 15: Set the user to run the application
USER node

# Step 16: Command to run the application
CMD ["sh", "-c", "node ./scripts/self-host-predeploy && node ./dist/index.js"]