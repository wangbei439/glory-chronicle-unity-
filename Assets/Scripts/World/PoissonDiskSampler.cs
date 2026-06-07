using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Poisson Disk 采样器
/// 确保生成的点位之间保持最小距离，避免物体重叠
/// 用法：PoissonDiskSampler.Sample(center, radius, minDistance, seed)
/// </summary>
public static class PoissonDiskSampler
{
    /// <summary>
    /// 在圆形区域内生成均匀分布的点
    /// </summary>
    /// <param name="center">圆心</param>
    /// <param name="radius">半径</param>
    /// <param name="minDistance">点之间的最小距离</param>
    /// <param name="seed">随机种子</param>
    /// <param name="maxSamples">最大采样次数，默认30</param>
    /// <returns>采样点列表</returns>
    public static List<Vector3> Sample(Vector3 center, float radius, float minDistance, int seed, int maxSamples = 30)
    {
        var points = new List<Vector3>();
        var activeList = new List<Vector3>();

        var rng = new System.Random(seed);

        float cellSize = minDistance / Mathf.Sqrt(2f);
        int gridW = Mathf.CeilToInt(radius * 2f / cellSize);
        int gridH = Mathf.CeilToInt(radius * 2f / cellSize);

        // 网格加速查找
        int[,] grid = new int[gridW, gridH];
        for (int x = 0; x < gridW; x++)
            for (int y = 0; y < gridH; y++)
                grid[x, y] = -1;

        // 初始点
        var firstPoint = new Vector3(
            center.x + (float)(rng.NextDouble() - 0.5) * radius,
            0,
            center.z + (float)(rng.NextDouble() - 0.5) * radius
        );

        // 确保在圆内
        while (Vector3.Distance(new Vector3(firstPoint.x, 0, firstPoint.z), center) > radius)
        {
            firstPoint = new Vector3(
                center.x + (float)(rng.NextDouble() - 0.5) * radius * 2,
                0,
                center.z + (float)(rng.NextDouble() - 0.5) * radius * 2
            );
        }

        points.Add(firstPoint);
        activeList.Add(firstPoint);
        SetGrid(grid, firstPoint, center, cellSize, gridW, gridH, 0);

        // 主循环
        int safetyCounter = 0;
        int maxIterations = 10000;

        while (activeList.Count > 0 && safetyCounter < maxIterations)
        {
            safetyCounter++;

            // 随机选一个活跃点
            int activeIdx = rng.Next(activeList.Count);
            var activePoint = activeList[activeIdx];

            bool found = false;

            for (int i = 0; i < maxSamples; i++)
            {
                // 在minDistance到2*minDistance的圆环内随机生成候选点
                float angle = (float)rng.NextDouble() * Mathf.PI * 2f;
                float dist = minDistance + (float)rng.NextDouble() * minDistance;

                var candidate = new Vector3(
                    activePoint.x + Mathf.Cos(angle) * dist,
                    0,
                    activePoint.z + Mathf.Sin(angle) * dist
                );

                // 检查是否在区域内
                if (Vector3.Distance(new Vector3(candidate.x, 0, candidate.z), center) > radius)
                    continue;

                // 检查是否与已有点保持最小距离
                if (IsTooClose(candidate, points, grid, center, cellSize, gridW, gridH, minDistance))
                    continue;

                // 通过！添加这个点
                points.Add(candidate);
                activeList.Add(candidate);
                SetGrid(grid, candidate, center, cellSize, gridW, gridH, points.Count - 1);
                found = true;
                break;
            }

            if (!found)
            {
                activeList.RemoveAt(activeIdx);
            }
        }

        return points;
    }

    /// <summary>
    /// 在环形区域内采样（内圈到外圈之间）
    /// </summary>
    public static List<Vector3> SampleRing(Vector3 center, float innerRadius, float outerRadius,
        float minDistance, int seed, int maxSamples = 30)
    {
        // 先在完整圆内采样，然后过滤出环形区域
        var allPoints = Sample(center, outerRadius, minDistance, seed, maxSamples);
        var ringPoints = new List<Vector3>();

        foreach (var p in allPoints)
        {
            float dist = Vector3.Distance(new Vector3(p.x, 0, p.z), center);
            if (dist >= innerRadius && dist <= outerRadius)
                ringPoints.Add(p);
        }

        return ringPoints;
    }

    /// <summary>
    /// 在两点之间的路径上采样
    /// </summary>
    public static List<Vector3> SamplePath(Vector3 from, Vector3 to, float pathWidth,
        float minDistance, int seed)
    {
        var points = new List<Vector3>();
        var rng = new System.Random(seed);

        Vector3 dir = (to - from).normalized;
        Vector3 perp = new Vector3(-dir.z, 0, dir.x); // 垂直方向

        float length = Vector3.Distance(from, to);
        int steps = Mathf.CeilToInt(length / minDistance);

        for (int i = 0; i <= steps; i++)
        {
            float t = (float)i / steps;
            Vector3 basePos = Vector3.Lerp(from, to, t);

            // 在路径宽度内随机偏移
            float offset = (float)(rng.NextDouble() - 0.5) * pathWidth;
            Vector3 pos = basePos + perp * offset;
            pos.y = 0;

            points.Add(pos);
        }

        return points;
    }

    static void SetGrid(int[,] grid, Vector3 point, Vector3 center, float cellSize, int gridW, int gridH, int index)
    {
        int gx = Mathf.FloorToInt((point.x - center.x + gridW * cellSize * 0.5f) / cellSize);
        int gy = Mathf.FloorToInt((point.z - center.z + gridH * cellSize * 0.5f) / cellSize);

        if (gx >= 0 && gx < gridW && gy >= 0 && gy < gridH)
            grid[gx, gy] = index;
    }

    static bool IsTooClose(Vector3 candidate, List<Vector3> points, int[,] grid,
        Vector3 center, float cellSize, int gridW, int gridH, float minDistance)
    {
        int gx = Mathf.FloorToInt((candidate.x - center.x + gridW * cellSize * 0.5f) / cellSize);
        int gy = Mathf.FloorToInt((candidate.z - center.z + gridH * cellSize * 0.5f) / cellSize);

        // 检查周围5x5网格
        int searchRadius = 2;
        for (int dx = -searchRadius; dx <= searchRadius; dx++)
        {
            for (int dy = -searchRadius; dy <= searchRadius; dy++)
            {
                int nx = gx + dx;
                int ny = gy + dy;

                if (nx < 0 || nx >= gridW || ny < 0 || ny >= gridH) continue;
                if (grid[nx, ny] < 0) continue;

                var other = points[grid[nx, ny]];
                float dist = Vector3.Distance(
                    new Vector3(candidate.x, 0, candidate.z),
                    new Vector3(other.x, 0, other.z)
                );

                if (dist < minDistance) return true;
            }
        }

        return false;
    }
}