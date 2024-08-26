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


# Step 6: Replace all "workspace:*" references in package.json with "1.0.0"
#RUN sed -i 's/"workspace:\*"/"1.0.0"/g' package.json 
   
# Step 7: Install application dependencies
RUN npm install --legacy-peer-deps

# Step 8: Build the application
RUN npm run build

# Step 9: Final stage to run the application
FROM node:18-alpine as final

# Step 10: Set the working directory
WORKDIR /app

# Step 11: Copy the built application from the base stage
COPY --from=base /app /app

# Step 12: Expose necessary ports
EXPOSE 3010
EXPOSE 5555

# Step 13: Set environment variables
ENV NODE_ENV=production
ENV DATABASE_URL=postgres://affine:affine@postgres:5432/affine
ENV REDIS_SERVER_HOST=redis

# Step 14: Command to run the application
CMD ["sh", "-c", "node ./scripts/self-host-predeploy && node ./dist/index.js"]
