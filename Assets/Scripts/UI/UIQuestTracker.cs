using UnityEngine;
using UnityEngine.UI;

public class UIQuestTracker : MonoBehaviour
{
    public Text questTitle;
    public Text questStep;

    void Update()
    {
        if (QuestManager.Instance == null) return;

        if (questTitle != null)
            questTitle.text = QuestManager.Instance.questName;

        if (questStep != null)
            questStep.text = QuestManager.Instance.GetStepHint(QuestManager.Instance.currentStep);
    }
}