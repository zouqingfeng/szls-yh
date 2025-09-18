Shader "Custom/SimpleWaterWithFoamAndHeaders"
{
    Properties
    {
        // 基础设置
        [Header(Base Settings)]
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _MainTexScale ("Main Texture Scale", Float) = 1.0
        _MainTexStrength ("Main Texture Strength", Range(0,1)) = 1.0 // 主纹理强度

        // 法线贴图设置
        [Header(Normal Map Settings)]
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpMapScale ("Normal Map Scale", Float) = 1.0
        _BumpMapStrength ("Normal Map Strength", Range(0,1)) = 1.0 // 法线贴图强度

        // 反射和折射设置
        [Header(Reflection and Refraction Settings)]
        _ReflectionTex ("Reflection Texture", 2D) = "white" {}
        _ReflectionTexScale ("Reflection Texture Scale", Float) = 1.0
        _ReflectionTexStrength ("Reflection Texture Strength", Range(0,1)) = 1.0 // 反射纹理强度
        _RefractionTex ("Refraction Texture", 2D) = "white" {}
        _RefractionTexScale ("Refraction Texture Scale", Float) = 1.0
        _RefractionTexStrength ("Refraction Texture Strength", Range(0,1)) = 1.0 // 折射纹理强度
        _ReflectionStrength ("Reflection Strength", Range(0,1)) = 0.5
        _RefractionStrength ("Refraction Strength", Range(0,1)) = 0.5

        // 波浪效果设置
        [Header(Wave Settings)]
        _WaveSpeed ("Wave Speed", Float) = 1.0
        _WaveScale ("Wave Scale", Float) = 1.0
        _FlowDirection ("Flow Direction", Vector) = (1, 0, 0, 0)

        // 水花效果设置
        [Header(Foam Settings)]
        _FoamColor ("Foam Color", Color) = (1,1,1,1)
        _FoamIntensity ("Foam Intensity", Range(0,1)) = 0.5
        _FoamThreshold ("Foam Threshold", Range(0,1)) = 0.1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float _MainTexScale;
            float _MainTexStrength; // 主纹理强度
            sampler2D _BumpMap;
            float _BumpMapScale;
            float _BumpMapStrength; // 法线贴图强度
            sampler2D _ReflectionTex;
            float _ReflectionTexScale;
            float _ReflectionTexStrength; // 反射纹理强度
            sampler2D _RefractionTex;
            float _RefractionTexScale;
            float _RefractionTexStrength; // 折射纹理强度
            float4 _Color;
            float _WaveSpeed;
            float _WaveScale;
            float _ReflectionStrength;
            float _RefractionStrength;
            float2 _FlowDirection;
            float4 _FoamColor;
            float _FoamIntensity;
            float _FoamThreshold;

            // 深度纹理相关
            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_TexelSize;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenPos = ComputeScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 根据水流方向调整UV偏移
                float2 flowDirection = normalize(_FlowDirection);
                float2 uv = i.uv + _Time.y * _WaveSpeed * flowDirection;

                // 计算波纹效果
                float2 bumpUV = uv * _BumpMapScale;
                float3 normal = UnpackNormal(tex2D(_BumpMap, bumpUV * _WaveScale));
                normal = lerp(float3(0, 0, 1), normal, _BumpMapStrength); // 应用法线贴图强度

                // 计算反射和折射
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                float2 reflectionUV = screenUV * _ReflectionTexScale + normal.xy * _ReflectionStrength;
                float2 refractionUV = screenUV * _RefractionTexScale + normal.xy * _RefractionStrength;

                fixed4 reflectionColor = tex2D(_ReflectionTex, reflectionUV) * _ReflectionTexStrength; // 应用反射纹理强度
                fixed4 refractionColor = tex2D(_RefractionTex, refractionUV) * _RefractionTexStrength; // 应用折射纹理强度

                // 混合反射和折射
                fixed4 finalColor = lerp(refractionColor, reflectionColor, _ReflectionStrength);

                // 应用主纹理和颜色
                float2 mainUV = uv * _MainTexScale;
                fixed4 mainTexColor = tex2D(_MainTex, mainUV) * _MainTexStrength; // 应用主纹理强度
                finalColor *= mainTexColor * _Color;

                // 计算深度信息
                float sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));
                float surfaceDepth = i.screenPos.w;

                // 计算深度差
                float depthDifference = sceneDepth - surfaceDepth;

                // 根据深度差生成水花效果
                float foam = smoothstep(_FoamThreshold, _FoamThreshold + 0.1, depthDifference);
                foam *= _FoamIntensity;

                // 混合水花颜色
                finalColor = lerp(finalColor, _FoamColor, foam);

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}