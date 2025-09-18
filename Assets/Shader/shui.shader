Shader "Custom/SimpleWaterWithFoamAndHeaders"
{
    Properties
    {
        // ��������
        [Header(Base Settings)]
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _MainTexScale ("Main Texture Scale", Float) = 1.0
        _MainTexStrength ("Main Texture Strength", Range(0,1)) = 1.0 // ������ǿ��

        // ������ͼ����
        [Header(Normal Map Settings)]
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpMapScale ("Normal Map Scale", Float) = 1.0
        _BumpMapStrength ("Normal Map Strength", Range(0,1)) = 1.0 // ������ͼǿ��

        // �������������
        [Header(Reflection and Refraction Settings)]
        _ReflectionTex ("Reflection Texture", 2D) = "white" {}
        _ReflectionTexScale ("Reflection Texture Scale", Float) = 1.0
        _ReflectionTexStrength ("Reflection Texture Strength", Range(0,1)) = 1.0 // ��������ǿ��
        _RefractionTex ("Refraction Texture", 2D) = "white" {}
        _RefractionTexScale ("Refraction Texture Scale", Float) = 1.0
        _RefractionTexStrength ("Refraction Texture Strength", Range(0,1)) = 1.0 // ��������ǿ��
        _ReflectionStrength ("Reflection Strength", Range(0,1)) = 0.5
        _RefractionStrength ("Refraction Strength", Range(0,1)) = 0.5

        // ����Ч������
        [Header(Wave Settings)]
        _WaveSpeed ("Wave Speed", Float) = 1.0
        _WaveScale ("Wave Scale", Float) = 1.0
        _FlowDirection ("Flow Direction", Vector) = (1, 0, 0, 0)

        // ˮ��Ч������
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
            float _MainTexStrength; // ������ǿ��
            sampler2D _BumpMap;
            float _BumpMapScale;
            float _BumpMapStrength; // ������ͼǿ��
            sampler2D _ReflectionTex;
            float _ReflectionTexScale;
            float _ReflectionTexStrength; // ��������ǿ��
            sampler2D _RefractionTex;
            float _RefractionTexScale;
            float _RefractionTexStrength; // ��������ǿ��
            float4 _Color;
            float _WaveSpeed;
            float _WaveScale;
            float _ReflectionStrength;
            float _RefractionStrength;
            float2 _FlowDirection;
            float4 _FoamColor;
            float _FoamIntensity;
            float _FoamThreshold;

            // ����������
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
                // ����ˮ���������UVƫ��
                float2 flowDirection = normalize(_FlowDirection);
                float2 uv = i.uv + _Time.y * _WaveSpeed * flowDirection;

                // ���㲨��Ч��
                float2 bumpUV = uv * _BumpMapScale;
                float3 normal = UnpackNormal(tex2D(_BumpMap, bumpUV * _WaveScale));
                normal = lerp(float3(0, 0, 1), normal, _BumpMapStrength); // Ӧ�÷�����ͼǿ��

                // ���㷴�������
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                float2 reflectionUV = screenUV * _ReflectionTexScale + normal.xy * _ReflectionStrength;
                float2 refractionUV = screenUV * _RefractionTexScale + normal.xy * _RefractionStrength;

                fixed4 reflectionColor = tex2D(_ReflectionTex, reflectionUV) * _ReflectionTexStrength; // Ӧ�÷�������ǿ��
                fixed4 refractionColor = tex2D(_RefractionTex, refractionUV) * _RefractionTexStrength; // Ӧ����������ǿ��

                // ��Ϸ��������
                fixed4 finalColor = lerp(refractionColor, reflectionColor, _ReflectionStrength);

                // Ӧ�����������ɫ
                float2 mainUV = uv * _MainTexScale;
                fixed4 mainTexColor = tex2D(_MainTex, mainUV) * _MainTexStrength; // Ӧ��������ǿ��
                finalColor *= mainTexColor * _Color;

                // ���������Ϣ
                float sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));
                float surfaceDepth = i.screenPos.w;

                // ������Ȳ�
                float depthDifference = sceneDepth - surfaceDepth;

                // ������Ȳ�����ˮ��Ч��
                float foam = smoothstep(_FoamThreshold, _FoamThreshold + 0.1, depthDifference);
                foam *= _FoamIntensity;

                // ���ˮ����ɫ
                finalColor = lerp(finalColor, _FoamColor, foam);

                return finalColor;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}