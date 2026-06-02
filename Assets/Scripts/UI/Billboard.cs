using UnityEngine;

public class Billboard : MonoBehaviour
{
    void LateUpdate()
    {
        Camera cam = Camera.current;
        if (cam != null)
            transform.rotation = cam.transform.rotation;
    }
}