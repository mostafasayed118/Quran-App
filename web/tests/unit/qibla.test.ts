import { describe, it, expect } from 'vitest';
import { qiblaBearing, KAABA } from '../../src/lib/qibla';

describe('qibla bearing', () => {
  it('Cairo faces ~136° (brief pin ±1°)', () => {
    expect(qiblaBearing(30.0444, 31.2357)).toBeCloseTo(136.14, 1);
  });

  it('the Kaaba itself is the degenerate self-point: 0°/360°', () => {
    expect(qiblaBearing(KAABA.lat, KAABA.lng)).toBe(0);
  });

  it('known-city spot checks', () => {
    expect(qiblaBearing(51.5074, -0.1278)).toBeCloseTo(118.99, 1); // London
    expect(qiblaBearing(40.7128, -74.006)).toBeCloseTo(58.48, 1); // New York
    expect(qiblaBearing(35.6762, 139.6503)).toBeCloseTo(293.0, 1); // Tokyo
  });

  it('always lands in [0, 360)', () => {
    const points = [
      [-36.8485, 174.7633], // Auckland
      [60.1699, 24.9384], // Helsinki
      [-33.8688, 151.2093], // Sydney
      [21.3891, 39.8579], // Makkah city centre (Kaaba is ~NW)
    ] as const;
    for (const [lat, lng] of points) {
      const bearing = qiblaBearing(lat, lng);
      expect(bearing).toBeGreaterThanOrEqual(0);
      expect(bearing).toBeLessThan(360);
    }
  });
});
