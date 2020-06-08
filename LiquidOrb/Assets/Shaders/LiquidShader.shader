Shader "MyShaders/LiquidShader"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        _Progress ("Progress", Range(0.0, 1.0)) = 0.5
        _WaterColor ("WaterColor", Color) = (1.0, 1.0, 0.2, 1.0)
        _WaveStrength ("WaveStrength", Float) = 2.0
        _WaveFrequency ("WaveFrequency", Float) = 180.0
        _WaterTransparency ("WaterTransparency", Float) = 1.0
        _WaterAngle ("WaterAngle", Float) = 4.0
        [MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
        [HideInInspector] _RendererColor ("RendererColor", Color) = (1,1,1,1)
        [HideInInspector] _Flip ("Flip", Vector) = (1,1,1,1)
        [PerRendererData] _AlphaTex ("External Alpha", 2D) = "white" {}
        [PerRendererData] _EnableExternalAlpha ("Enable External Alpha", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
        CGPROGRAM
            #pragma vertex SpriteVert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_instancing
            #pragma multi_compile_local _ PIXELSNAP_ON
            #pragma multi_compile _ ETC1_EXTERNAL_ALPHA
            #include "UnitySprites.cginc"

            float _Progress;
            fixed4 _WaterColor;
            float _WaveStrength;
            float _WaveFrequency;
            float _WaterTransparency;
            float _WaterAngle;

            fixed4 drawWater(fixed4 water_color, sampler2D color, float transparency, float height, float angle, float wave_strength, float wave_ratio, fixed2 uv);
            fixed4 frag (v2f i) : SV_Target
            {
                fixed2 uv = i.texcoord;
                float WATER_HEIGHT = _Progress;
                float4 WATER_COLOR = _WaterColor;
                float WAVE_STRENGTH = _WaveStrength;
                float WAVE_FREQUENCY = _WaveFrequency;
                float WATER_TRANSPARENCY = _WaterTransparency;
                float WATER_ANGLE = _WaterAngle;

                fixed4 fragColor = drawWater(WATER_COLOR, _MainTex, WATER_TRANSPARENCY, WATER_HEIGHT, WATER_ANGLE, WAVE_STRENGTH, WAVE_FREQUENCY, uv);
                return fragColor;
            }

            fixed4 drawWater(fixed4 water_color, sampler2D color, float transparency, float height, float angle, float wave_strength, float wave_frequency, fixed2 uv)
            {
                float iTime = _Time;
                angle *= uv.y/height+angle/1.5; //3D effect
                wave_strength /= 1000.0;
                float wave = sin(10.0*uv.y+10.0*uv.x+wave_frequency*iTime)*wave_strength;
                wave += sin(20.0*-uv.y+20.0*uv.x+wave_frequency*1.0*iTime)*wave_strength*0.5;
                wave += sin(15.0*-uv.y+15.0*-uv.x+wave_frequency*0.6*iTime)*wave_strength*1.3;
                wave += sin(3.0*-uv.y+3.0*-uv.x+wave_frequency*0.3*iTime)*wave_strength*10.0;
                
                if(uv.y - wave <= height)
                    return lerp(
                    lerp(
                        tex2D(color, fixed2(uv.x, ((1.0 + angle)*(height + wave) - angle*uv.y + wave))),
                        water_color,
                        0.6-(0.3-(0.3*uv.y/height))),
                    tex2D(color, fixed2(uv.x + wave, uv.y - wave)),
                    transparency-(transparency*uv.y/height));
                else
                    return fixed4(0,0,0,0);
            }
        ENDCG
        }
    }
}
