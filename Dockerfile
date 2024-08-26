# Step 1: Base image for building the application
FROM node:18-alpine as build

# Step 2: Set the working directory
WORKDIR /app

# Step 3: Install system dependencies
RUN apk add --no-cache git python3 make g++ curl

# Step 4: Clone the forked repository and switch to the stable branch
RUN git clone https://github.com/blueprintkey/AFFiNE.git .
RUN git checkout stable

# Step 5: Remove any existing node_modules and yarn.lock to avoid conflicts
RUN rm -rf node_modules yarn.lock

# Step 6: Install Yarn globally
RUN npm install -g yarn

# Step 7: Install application dependencies using Yarn with caching
RUN yarn install --frozen-lockfile --network-timeout 100000

# Step 8: Build the application
RUN yarn build

# Step 9: Create a minimal production image
FROM node:18-alpine as production

# Step 10: Set the working directory
WORKDIR /app

# Step 11: Copy the built application from the build stage
COPY --from=build /app /app

# Step 12: Install production dependencies only
RUN yarn install --production --frozen-lockfile --network-timeout 100000 && \
    yarn cache clean

# Step 13: Expose necessary ports
EXPOSE 3010
EXPOSE 5555

# Step 14: Set environment variables
ENV NODE_ENV=production
ENV DATABASE_URL=postgres://affine:affine@postgres:5432/affine
ENV REDIS_SERVER_HOST=redis

# Step 15: Add a health check (optional, customize as needed)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3010/health || exit 1

# Step 16: Set the user to run the application
USER node

# Step 17: Command to run the application
CMD ["sh", "-c", "node ./scripts/self-host-predeploy && node ./dist/index.js"]