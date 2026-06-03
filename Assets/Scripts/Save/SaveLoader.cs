using UnityEngine;

public class SaveLoader : MonoBehaviour
{
    void Start()
    {
        if (SaveManager.Instance != null && SaveManager.Instance.HasSave())
        {
            SaveManager.Instance.Load();
        }
    }
}