#%%
import numpy as np
import matplotlib.pyplot as plt
plt. rcParams [ 'font.family' ] = 'Times New Roman, '
plt. rcParams [ 'font.size' ] = 20
plt.rcParams['mathtext.fontset'] = 'stix'
plt.rc('font', family='Times New Roman')
def plot_geopotential_and_wind(zc, uc, vc, ax=None, vmin=None, vmax=None, experiment=''):
    """
    绘制500hPa位势高度场和风场矢量图。
    111
    参数:
        zc: 2D数组，位势高度场数据
        uc: 2D数组，u方向风速
        vc: 2D数组，v方向风速
        ax: matplotlib的Axes对象，可选。如果提供，将在该Axes上绘图。
        vmin: 色标的最小值
        vmax: 色标的最大值
        experiment: 实验名称，用于标题
    """
    x = np.arange(zc.shape[1])
    y = np.arange(zc.shape[0])
    X, Y = np.meshgrid(x, y)
    if ax is None:
        fig, ax = plt.subplots(figsize=(14, 8), dpi=300)
    # 绘制位势高度场等高线
    contourf = ax.contourf(X, Y, zc, levels=40, cmap='coolwarm', vmin=vmin, vmax=vmax)
    contour = ax.contour(X, Y, zc, levels=10, colors='black', linewidths=0.4,
                          alpha=0.6)
    ax.clabel(contour, inline=True, fontsize=8, fmt='%1.0f')  # 添加等高线标签
    ax.set_title(f'500hPa Geopotential Height ({experiment})', fontsize=20)
    ax.set_xlabel('Longitude Index')
    ax.set_ylabel('Latitude Index')
    # 绘制风场矢量图
    quiver = ax.quiver(X, Y, uc, vc, scale=450, color='black', alpha=0.6, width=0.0025)
    # 添加风矢量大小的图例
    ax.quiverkey(quiver, X=0.9, Y=1.05, U=10, label='10 m/s', labelpos='E')
    ax.grid()
    return contourf
#%%初始场
zc1 = np.loadtxt('d:\\NCW\\zc_nots_fb.dat')
uc1 = np.loadtxt('d:\\NCW\\uc_nots_fb.dat')
vc1 = np.loadtxt('d:\\NCW\\vc_nots_fb.dat')
zc2 = np.loadtxt('d:\\NCW\\zc_nots_b.dat')
uc2 = np.loadtxt('d:\\NCW\\uc_nots_b.dat')
vc2 = np.loadtxt('d:\\NCW\\vc_nots_b.dat')
z_diff = zc1 - zc2
u_diff = uc1 - uc2
v_diff = vc1 - vc2
p = plot_geopotential_and_wind(z_diff, u_diff, v_diff, experiment='Difference for Exp4')
cbar = plt.colorbar(p, orientation='vertical', label='Geopotential Height (m)')
plt.tight_layout(rect=[0, 0.2, 0.8, 1])  # 调整布局，留出下方空间
#%%
# 设置统一的色标范围
vmin = min(zc1.min(), zc2.min())
vmax = max(zc1.max(), zc2.max())
# 创建子图并绘制
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(18, 8), dpi=300)
contourf1 = plot_geopotential_and_wind(zc1, uc1, vc1, ax=ax1,
                                        vmin=vmin, vmax=vmax, experiment='with Time Smoothing')
contourf2 = plot_geopotential_and_wind(zc2, uc2, vc2, ax=ax2,
                                        vmin=vmin, vmax=vmax, experiment='with Time Smoothing')

from matplotlib.cm import ScalarMappable
from matplotlib.colors import Normalize
norm = Normalize(vmin=vmin, vmax=vmax)  # 使用统一的 vmin 和 vmax
sm = ScalarMappable(cmap='coolwarm', norm=norm)  # 创建 ScalarMappable
sm.set_array([])  # 必须设置 array 才能生成 colorbar
cbar = fig.colorbar(sm, ax=[ax1, ax2], orientation='horizontal',
                     label='Geopotential Height (m)', shrink=0.8, aspect=30)
ax1.text(0.02, 1.03, '(a)',transform=ax1.transAxes, fontsize=25,fontweight='bold')
ax2.text(0.02, 1.03, '(b)',transform=ax2.transAxes, fontsize=25,fontweight='bold')
plt.tight_layout(rect=[0, 0.3, 1, 1])  # 调整布局，留出下方空间
plt.show()
