// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "UI/Default"
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

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
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

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "Default"
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                half4  mask : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            float _MaskSoftnessX;
            float _MaskSoftnessY;

            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                float4 vPosition = UnityObjectToClipPos(v.vertex);
                OUT.worldPosition = v.vertex;
                OUT.vertex = vPosition;

                float2 pixelSize = vPosition.w;
                pixelSize /= float2(1, 1) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));

                float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
                OUT.texcoord = float4(v.texcoord.x, v.texcoord.y, maskUV.x, maskUV.y);
                OUT.mask = half4(v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_MaskSoftnessX, _MaskSoftnessY) + abs(pixelSize.xy)));

                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 fragPrevious(v2f IN) : SV_Target
            {
                half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;

                #ifdef UNITY_UI_CLIP_RECT
                half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw);
                color.a *= m.x * m.y;
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                return color;
            }

        
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

         
                #ifdef UNITY_UI_CLIP_RECT
                half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(i.mask.xy)) * i.mask.zw);
                fragColor.a *= m.x * m.y;
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                fragColor (color.a - 0.001);
                #endif
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
