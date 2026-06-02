using UnityEngine;
using System.Collections;

public class SpawnZone : MonoBehaviour
{
    [Header("刷新设置")]
    public GameObject enemyPrefab;
    public int maxEnemies = 3;
    public float spawnInterval = 3f;
    public float spawnRadius = 5f;

    [Header("绑定POI（可选）")]
    public string requiredPOIId = "";  // 留空=一开始就刷，填了=发现POI后才刷

    private int currentCount = 0;
    private bool isActive = false;

    void Start()
    {
        if (string.IsNullOrEmpty(requiredPOIId))
        {
            // 没绑定POI，一开始就刷
            Activate();
        }
        else
        {
            // 检查是否已经发现过
            if (WorldManager.Instance != null && WorldManager.Instance.IsPOIDiscovered(requiredPOIId))
            {
                Activate();
            }
        }
    }

    void Update()
    {
        // 还没激活，持续检查POI是否被发现
        if (!isActive && !string.IsNullOrEmpty(requiredPOIId))
        {
            if (WorldManager.Instance != null && WorldManager.Instance.IsPOIDiscovered(requiredPOIId))
            {
                Activate();
            }
        }
    }

    void Activate()
    {
        isActive = true;
        for (int i = 0; i < maxEnemies; i++)
        {
            SpawnEnemy();
        }
    }

    void SpawnEnemy()
    {
        if (enemyPrefab == null) return;

        Vector2 randomCircle = Random.insideUnitCircle * spawnRadius;
        Vector3 spawnPos = transform.position + new Vector3(randomCircle.x, 0.5f, randomCircle.y);

        GameObject enemy = Instantiate(enemyPrefab, spawnPos, Quaternion.identity);
        currentCount++;

        Dummy dummy = enemy.GetComponent<Dummy>();
        if (dummy != null)
        {
            dummy.OnDeath += HandleEnemyDeath;
        }
    }

    void HandleEnemyDeath()
    {
        currentCount--;
        StartCoroutine(RespawnAfterDelay());
    }

    IEnumerator RespawnAfterDelay()
    {
        yield return new WaitForSeconds(spawnInterval);
        if (currentCount < maxEnemies && isActive)
        {
            SpawnEnemy();
        }
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.color = isActive ? new Color(1f, 0f, 0f, 0.3f) : new Color(0.5f, 0.5f, 0.5f, 0.2f);
        Gizmos.DrawSphere(transform.position, spawnRadius);
    }
}