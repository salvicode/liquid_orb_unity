using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LiquidProgressController : MonoBehaviour
{
    public SpriteRenderer LiquidRenderer;
    public float AccumulatedTime;
    public float DelayCoef = 0.5f;

    // Update is called once per frame
    void Update()
    {
        AccumulatedTime += Time.deltaTime * DelayCoef;
        LiquidRenderer.material.SetFloat("_Progress", Mathf.Abs(Mathf.Sin(AccumulatedTime)));
    }
}
