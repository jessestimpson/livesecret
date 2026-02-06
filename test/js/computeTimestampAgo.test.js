import { describe, test, expect } from "bun:test";
import { getAgoString } from "../../assets/js/hooks/computeTimestampAgo.js";

describe("getAgoString", () => {
  test("returns 'less than a minute ago' for recent timestamps", () => {
    const now = new Date();
    const tenSecondsAgo = new Date(now.getTime() - 10 * 1000);
    const result = getAgoString(tenSecondsAgo);
    expect(result).toContain("less than a minute ago");
  });

  test("returns seconds for admin format", () => {
    const now = new Date();
    const tenSecondsAgo = new Date(now.getTime() - 10 * 1000);
    const result = getAgoString(tenSecondsAgo, "admin");
    expect(result).toContain("10 seconds ago");
  });

  test("returns '0 seconds ago' for admin format with now", () => {
    const now = new Date();
    const result = getAgoString(now, "admin");
    expect(result).toContain("0 seconds ago");
  });

  test("returns '1 second ago' for admin format (singular)", () => {
    const now = new Date();
    const oneSecondAgo = new Date(now.getTime() - 1 * 1000);
    const result = getAgoString(oneSecondAgo, "admin");
    expect(result).toContain("1 second ago");
    expect(result).not.toContain("seconds");
  });

  test("returns minutes ago", () => {
    const now = new Date();
    const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000);
    const result = getAgoString(fiveMinutesAgo);
    expect(result).toContain("5 minutes ago");
  });

  test("returns '1 minute ago' (singular)", () => {
    const now = new Date();
    const oneMinuteAgo = new Date(now.getTime() - 61 * 1000);
    const result = getAgoString(oneMinuteAgo);
    expect(result).toContain("1 minute ago");
    expect(result).not.toContain("minutes");
  });

  test("returns hours ago", () => {
    const now = new Date();
    const threeHoursAgo = new Date(now.getTime() - 3 * 60 * 60 * 1000);
    const result = getAgoString(threeHoursAgo);
    expect(result).toContain("3 hours ago");
  });

  test("returns days ago", () => {
    const now = new Date();
    const twoDaysAgo = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000);
    const result = getAgoString(twoDaysAgo);
    expect(result).toContain("2 days ago");
  });

  test("returns months ago", () => {
    const now = new Date();
    const twoMonthsAgo = new Date(now.getTime() - 62 * 24 * 60 * 60 * 1000);
    const result = getAgoString(twoMonthsAgo);
    expect(result).toContain("2 months ago");
  });

  test("returns years ago", () => {
    const now = new Date();
    const twoYearsAgo = new Date(now.getTime() - 730 * 24 * 60 * 60 * 1000);
    const result = getAgoString(twoYearsAgo);
    expect(result).toContain("2 years ago");
  });

  test("includes time string in parenthetical format", () => {
    const now = new Date();
    const result = getAgoString(now);
    // Format: "12:34 PM (less than a minute ago)"
    expect(result).toMatch(/\(.*ago\)/);
  });
});
