using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LiquidProgressControllerUI : MonoBehaviour
{
    public CanvasRenderer LiquidRenderer;
    public float AccumulatedTime;
    public float DelayCoef = 0.5f;

    // Update is called once per frame
    void Update()
    {
        AccumulatedTime += Time.deltaTime * DelayCoef;
        if (LiquidRenderer.GetMaterial() != null)
        {
            LiquidRenderer.GetMaterial().SetFloat("_Progress", Mathf.Abs(Mathf.Sin(AccumulatedTime)));
        }
    }
}
