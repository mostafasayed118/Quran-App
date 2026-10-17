import { describe, it, expect } from 'vitest';
import { otherTheme, readTheme, THEME_KEY } from '../../src/lib/theme';

describe('theme', () => {
  it('flips between day and night', () => {
    expect(otherTheme('day')).toBe('night');
    expect(otherTheme('night')).toBe('day');
  });
  it('reads a saved preference first', () => {
    expect(readTheme({ getItem: () => 'night' }, false)).toBe('night');
    expect(readTheme({ getItem: () => 'day' }, true)).toBe('day');
  });
  it('falls back to system preference', () => {
    expect(readTheme({ getItem: () => null }, true)).toBe('night');
    expect(readTheme(null, false)).toBe('day');
  });
  it('uses the namespaced key', () => expect(THEME_KEY).toBe('qy:theme'));
});
