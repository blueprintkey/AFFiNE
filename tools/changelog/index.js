import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { Repository, Sort } from '@napi-rs/simple-git';
import { WebClient } from '@slack/web-api';
import {
  generateMarkdown,
  parseCommits,
  resolveAuthors,
  resolveConfig,
} from 'changelogithub';

import { render } from './markdown.js';

const { DEPLOYED_URL, NAMESPACE, CHANNEL_ID, SLACK_BOT_TOKEN, PREV_VERSION } =
  process.env;

const slack = new WebClient(SLACK_BOT_TOKEN);
const repo = new Repository(
  join(fileURLToPath(import.meta.url), '..', '..', '..')
);

const previous = repo.findCommit(PREV_VERSION);

/** @type {typeof import('changelogithub')['parseCommits'] extends (commit: infer C, ...args: any[]) => any ? C : any} */
const commits = [];

for (const commitId of repo
  .revWalk()
  .pushHead()
  .setSorting(Sort.Time & Sort.Topological)) {
  const commit = repo.findCommit(commitId);
  commits.push({
    message: commit.message(),
    body: commit.body() ?? '',
    shortHash: commit.id().substring(0, 8),
    author: {
      name: commit.author().name(),
      email: commit.author().email(),
    },
  });
  if (commitId === previous.id()) {
    break;
  }
}

const parseConfig = await resolveConfig({
  token: process.env.GITHUB_TOKEN,
});

const parsedCommits = parseCommits(commits, parseConfig);
await resolveAuthors(parsedCommits, parseConfig);

const { ok } = await slack.chat.postMessage({
  channel: CHANNEL_ID,
  text: `Server deployed`,
  blocks: render(`
# Server deployed in ${NAMESPACE}

- [${DEPLOYED_URL}](${DEPLOYED_URL})

${generateMarkdown(parsedCommits, parseConfig).replaceAll('&nbsp;', ' ').replaceAll('<samp>', '').replaceAll('</samp>', '')}
`),
});

console.assert(ok, 'Failed to send a message to Slack');
