/**
 * @format
 */

import React from 'react';
import ReactTestRenderer from 'react-test-renderer';

jest.mock('rn-videofeed', () => {
  const ReactNative = require('react-native');
  return {
    __esModule: true,
    default: ReactNative.View,
    VideoFeedView: ReactNative.View,
    VideoFeedManagerNative: {
      setVideos: jest.fn(),
      appendVideos: jest.fn(),
      setFeedActive: jest.fn(),
    },
    VideoFeedEmitter: {
      addListener: jest.fn(() => ({remove: jest.fn()})),
    },
  };
});

import App from '../App';

test('renders correctly', async () => {
  jest.useFakeTimers();
  let tree: ReactTestRenderer.ReactTestRenderer | undefined;
  await ReactTestRenderer.act(() => {
    tree = ReactTestRenderer.create(<App />);
  });
  await ReactTestRenderer.act(() => {
    jest.runOnlyPendingTimers();
  });
  tree?.unmount();
  jest.useRealTimers();
});
