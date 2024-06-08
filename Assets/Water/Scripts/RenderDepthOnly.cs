using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RenderDepthOnly : ScriptableRendererFeature
{
    public LayerMask layerMask;
    RenderDepthOnlyPass m_RenderDepthOnlyPass;
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (renderingData.cameraData.requiresDepthTexture) return;
        renderer.EnqueuePass(m_RenderDepthOnlyPass);
    }
    public override void Create()
    {
        m_RenderDepthOnlyPass = new RenderDepthOnlyPass(layerMask);
        m_RenderDepthOnlyPass.renderPassEvent = RenderPassEvent.BeforeRenderingPrePasses;
    }

    class RenderDepthOnlyPass : ScriptableRenderPass
    {
        RTHandle m_RTHandle;
        DrawingSettings m_DrawingSettings;
        FilteringSettings m_FilteringSettings;
        SortingCriteria m_SortingCriteria;

        public RenderDepthOnlyPass(LayerMask layerMask)
        {
            m_SortingCriteria = SortingCriteria.CommonOpaque;
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.opaque, layerMask);
        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            base.OnCameraSetup(cmd, ref renderingData);
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            RenderingUtils.ReAllocateIfNeeded(ref m_RTHandle, descriptor, name: "_WaterDepthTexture");
            ConfigureTarget(m_RTHandle);
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("Water Depth");
            cmd.SetGlobalTexture("_WaterDepthTexture", m_RTHandle);
            cmd.ClearRenderTarget(true, false, Color.black);
            context.ExecuteCommandBuffer(cmd);
            cmd.Release();
            m_DrawingSettings = CreateDrawingSettings(new ShaderTagId("DepthOnly"), ref renderingData, m_SortingCriteria);
            context.DrawRenderers(renderingData.cullResults, ref m_DrawingSettings, ref m_FilteringSettings);
        }
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            base.OnCameraCleanup(cmd);
            m_RTHandle.Release();
        }
    }
}