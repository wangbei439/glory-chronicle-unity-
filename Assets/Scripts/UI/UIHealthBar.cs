using UnityEngine;
using UnityEngine.UI;

public class UIHealthBar : MonoBehaviour
{
    public PlayerStats playerStats;
    public Image fillImage;
    public Text hpText;

    void Update()
    {
        if (playerStats == null)
        {
            GameObject player = GameObject.FindGameObjectWithTag("Player");
            if (player != null)
                playerStats = player.GetComponent<PlayerStats>();
            return;
        }

        float ratio = (float)playerStats.hp / playerStats.maxHp;
        if (fillImage != null)
            fillImage.fillAmount = ratio;

        if (hpText != null)
            hpText.text = playerStats.hp + " / " + playerStats.maxHp;
    }
}