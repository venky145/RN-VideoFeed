const path = require('path');
const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');

/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 *
 * Linked `rn-videofeed` lives outside this app folder; resolving hoisted deps
 * (e.g. @babel/runtime) must explicitly use VideoFeedSample/node_modules.
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */
const projectRoot = __dirname;
const appNodeModules = path.resolve(projectRoot, 'node_modules');

module.exports = mergeConfig(getDefaultConfig(projectRoot), {
  watchFolders: [path.resolve(projectRoot, '..', 'rn-videofeed')],
  resolver: {
    nodeModulesPaths: [appNodeModules],
    extraNodeModules: {
      '@babel/runtime': path.resolve(appNodeModules, '@babel/runtime'),
    },
  },
});
