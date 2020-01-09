Shader "Custom/PaletteReplacement"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _PaletteTex ("Palette", 2D) = "white" {}
        [Toggle(REPLACE_PALETTE)] _ReplacePalette("Replace Palette", Float) = 0
        [Toggle(APPLY_GAMMA)] _ApplyGamma("Apply Gamma Correction", Float) = 0
        [Toggle(APPLY_CONTRAST)] _ApplyContrast("Apply Contrast", Float) = 0
        [Toggle(FLIP_DIRECTION)] _FlipDirection("Flip Direction", Float) = 0
        _Gamma ("Gamma", Range(0,5)) = 1.0
        _Contrast ("Contrast", Range(0,5)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #pragma multi_compile _ REPLACE_PALETTE
            #pragma multi_compile _ APPLY_GAMMA
            #pragma multi_compile _ APPLY_CONTRAST
            #pragma multi_compile _ FLIP_DIRECTION

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };


            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };


            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            sampler2D _PaletteTex;
            float4 _PaletteTex_ST;
            float4 _PaletteTex_TexelSize;

            float _Gamma;
            float _Contrast;


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }


            float Luma(float3 col)
            {
                return float(col.r * 0.299 + col.g * 0.587 + col.b * 0.114);
            }


            fixed4 AdjustGamma (fixed4 col, float gamma)
            {
                col.rgb = pow(col, (1.0 / gamma));
                return col;
            }


            half4 AdjustContrast(half4 color, float contrast)
            {
                return saturate(lerp(half4(0.5, 0.5, 0.5, 0.5), color, contrast));
            }


            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                #ifdef APPLY_GAMMA
                    col = AdjustGamma(col, _Gamma);
                #endif

                #ifdef APPLY_CONTRAST
                    col = AdjustContrast(col, _Contrast);
                #endif

                #ifdef REPLACE_PALETTE
                    float halfTexel = _PaletteTex_TexelSize.x / 2;
                    float2 paletteUV = float2(Luma(col.rgb) - halfTexel, 0.5);
                    #ifdef FLIP_DIRECTION
                        paletteUV.x = 1.0 - paletteUV.x;
                    #endif
                    col.rgb = tex2D( _PaletteTex, paletteUV);
                #endif

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
