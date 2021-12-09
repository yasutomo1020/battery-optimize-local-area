import math
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import datetime as dt
import copy
from matplotlib import cm
plt.rcParams['font.family'] = "MS Gothic"


def Panel(a, theta_a, N, A, alpha, theta_z, day, time):  # 方位角，仰角，パネル枚数 aは0~90
    if N == 0:
        return 0
    else:
        Aa = A * 180 / math.pi - a  # 90~280

        theta[time] = math.acos(math.sin(alpha) * math.cos(theta_a * math.pi / 180)
                                + math.cos(alpha) * math.sin(theta_a * math.pi / 180) * math.cos(Aa * math.pi / 180))

        hb[day][time] = Hb[day][time] * \
            math.cos(theta[time]) / math.cos(theta_z[time])
        if hb[day][time] <= 0:
            hb[day][time] = 0
        if theta[time] > math.pi / 2:
            hb[day][time] = 0
        if alpha < math.radians(10):
            hb[day][time] = 0

        hr[day][time] = H[day][time] * p * \
            (1 - math.cos(theta_a * math.pi / 180)) / 2
        if hr[day][time] <= 0:
            hr[day][time] = 0

        hd[day][time] = Hd[day][time] * \
            (1 + math.cos(theta_a * math.pi / 180)) / 2
        if hd[day][time] <= 0:
            hd[day][time] = 0

        h[day][time] = (hb[day][time] + hr[day][time] + hd[day][time])
        # h[day][time] = 1000

        Temp[time] = 25 + 273

        Iph[time] = (Iph_cell * N + KI * (Temp[time] - 298)) * \
            h[day][time] / Gn

        if N <= 1:
            I0_n[time] = Isc_n
        else:
            I0_n[time] = Isc_n / \
                (math.exp(Voc_n / (c * N * k * Temp[time] / q)) - 1)

        I0[time] = I0_n[time] * ((298 / Temp[time]) ** 3) * math.exp(q * Eg / (c * k) * (1 / 298
                                                                                         - 1 / Temp[time]))

        if N <= 1:
            Ipv[time] = Iph[time]
        else:
            Ipv[time] = Iph[time] - I0[time] * \
                (math.exp(q * Vpv / (N * k * Temp[time] * c)) - 1)

        Wpv[time] = 0.80 * (Vpv * Ipv[time])
        if Wpv[time] <= 0:
            Wpv[time] = 0.0

        return Wpv[time]
############################################################################################################
############################################################################################################


def Power(N, Na, a, theta_a, dn):
    while N <= Na:
        Ppv = 0
        day = dn - 1
        for time in range(24):  # timeを24時間の間で
            time2 = time + 1
            # 楕円軌道上の地球の位置[rad]
            ganma = 2 * math.pi * (dn - 1) / 365
            delta = (0.006918 - 0.399912 * math.cos(ganma) + 0.070257 * math.sin(ganma)
                     - 0.006758 * math.cos(2 * ganma) +
                     0.000907 * math.sin(2 * ganma)
                     - 0.002697 * math.cos(3 * ganma) + 0.00148 * math.sin(3 * ganma)) * (180 / math.pi)                      # 赤緯[deg]
            e = (0.000075 + 0.001868 * math.cos(ganma) - 0.032077 * math.sin(ganma)
                 - 0.014615 * math.cos(2 * ganma) - 0.04089 * math.sin(2 * ganma)) * 229.18      # 均時差[min]
            # 真太陽時[h]
            Hs = time2 + (4 * (lamda - 135)) / 60 + e / 60
            if time2 < 12:
                omega = 15 * (Hs + 12)
            else:
                # 時角[deg]
                omega = 15 * (Hs - 12)

            alpha[time] = math.asin(math.sin(math.radians(phi)) * math.sin(math.radians(delta)) + math.cos(math.radians(phi))
                                    * math.cos(math.radians(delta)) * math.cos(math.radians(omega)))                # 太陽高度[rad]
            As[time] = math.sin(math.radians(
                omega)) * math.cos(math.radians(delta)) / math.cos(alpha[time])      # 太陽の方位角AのsinA
            Ac[time] = (math.sin(math.radians(phi)) * math.sin(alpha[time]) - math.sin(math.radians(delta)))\
                / (math.cos(math.radians(phi)) * math.cos(alpha[time]))                                          # 太陽の方位角AのcosA
            # 太陽方位角A[rad]
            A[time] = math.atan(As[time]/Ac[time])
            if As[time] < 0 and Ac[time] < 0:
                A[time] = A[time]
            elif As[time] > 0 and Ac[time] < 0:
                A[time] = A[time] + 2 * math.pi
            else:
                A[time] = A[time] + math.pi

            theta_z[time] = math.pi / 2 - alpha[time]  # theta_z:天頂角

            # ====関数実行=======================================================
            Wpv[time] = Panel(a, theta_a, N, A[time],
                              alpha[time], theta_z, day, time)
            # ==================================================================

            # Ppv = round (Ppv + Wpv[time], 3)                           #小数第3位に四捨五入
        N += 1
    return Wpv
###############################################################################################################
###############################################################################################################


def Power2(N, Na, a, theta_a, dn):
    while N <= Na:
        Ppv = 0
        day = dn - 1
        for time in range(24):  # timeを24時間の間で
            time2 = time + 1
            # 楕円軌道上の地球の位置[rad]
            ganma = 2 * math.pi * (dn - 1) / 365
            delta = (0.006918 - 0.399912 * math.cos(ganma) + 0.070257 * math.sin(ganma)
                     - 0.006758 * math.cos(2 * ganma) +
                     0.000907 * math.sin(2 * ganma)
                     - 0.002697 * math.cos(3 * ganma) + 0.00148 * math.sin(3 * ganma)) * (180 / math.pi)                      # 赤緯[deg]
            e = (0.000075 + 0.001868 * math.cos(ganma) - 0.032077 * math.sin(ganma)
                 - 0.014615 * math.cos(2 * ganma) - 0.04089 * math.sin(2 * ganma)) * 229.18      # 均時差[min]
            # 真太陽時[h]
            Hs = time2 + (4 * (lamda - 135)) / 60 + e / 60
            if time2 < 12:
                omega = 15 * (Hs + 12)
            else:
                # 時角[deg]
                omega = 15 * (Hs - 12)

            alpha[time] = math.asin(math.sin(math.radians(phi)) * math.sin(math.radians(delta)) + math.cos(math.radians(phi))
                                    * math.cos(math.radians(delta)) * math.cos(math.radians(omega)))                                      # 太陽高度[rad]
            As[time] = math.sin(math.radians(
                omega)) * math.cos(math.radians(delta)) / math.cos(alpha[time])      # 太陽の方位角AのsinA
            Ac[time] = (math.sin(math.radians(phi)) * math.sin(alpha[time]) - math.sin(math.radians(delta)))\
                / (math.cos(math.radians(phi)) * math.cos(alpha[time]))                                          # 太陽の方位角AのcosA
            # 太陽方位角A[rad]
            A[time] = math.atan(As[time]/Ac[time])
            if As[time] < 0 and Ac[time] < 0:
                A[time] = A[time]
            elif As[time] > 0 and Ac[time] < 0:
                A[time] = A[time] + 2 * math.pi
            else:
                A[time] = A[time] + math.pi

            theta_z[time] = math.pi / 2 - alpha[time]  # theta_z:天頂角
            # print(f"{time+1}時theta_z:{theta_z[time]}")

            # ====関数実行=======================================================
            a2 = a + 180
            theta_a2 = 180 - theta_a
            Wpv[time] = Panel(a, theta_a, N, A[time], alpha[time], theta_z, day, time) + \
                Panel(a2, theta_a2, N, A[time],
                      alpha[time], theta_z, day, time) * 0.7
            # print(f"{time+1}時hb:{hb[day][time]},hr:{hr[day][time]},hd:{hd[day][time]}")
            # print(f"{time+1}時theta_z:{theta[time]}")

            # ==================================================================

            # Ppv = round (Ppv + Wpv[time], 3)                           #小数第3位に四捨五入
        N += 1
    return Wpv


###############################################################################################################
# ##====installation==================================================================
hoge = [0, 0, 0, 0, 0, 0, 0]
N_panel = 1  # パネルの枚数
Tilt_angle = 24
# #====片面受光================================================
# #====south=====================
a_s = 180  # Azimuth(方位角)
theta_a_s = Tilt_angle  # Tilt_angl = 0(傾き)
N_s = N_panel  # 過積載100%枚数40枚
Na_s = N_s
hoge[0] = 1  # 真南設置の時の判別(hoge=[1,0,0,0,0])

# #====west=====================
a_w = 270  # Azimuth(方位角)
theta_a_w = Tilt_angle  # Tilt_angl = 0(傾き)
N_w = N_panel  # 過積載100%枚数40枚
Na_w = N_w
hoge[1] = 1  # 西側設置の時の判別(hoge=[0,1,0,0,0])

# #====south_west=====================
a_sw = 225  # Azimuth(方位角)
theta_a_sw = Tilt_angle  # Tilt_angl = 0(傾き)
N_sw = N_panel  # 過積載100%枚数40枚
Na_sw = N_sw
hoge[2] = 1  # 南西設置の時の判別(hoge=[0,0,1,0,0])

# #====east=====================
a_e = 90  # Azimuth(方位角)
theta_a_e = Tilt_angle  # Tilt_angl = 0(傾き)
N_e = N_panel  # 過積載100%枚数40枚
Na_e = N_e
hoge[3] = 1  # 西側設置の時の判別(hoge=[0,1,0,0,0])

# #====south_east=====================
a_se = 135  # Azimuth(方位角)
theta_a_se = Tilt_angle  # Tilt_angl = 0(傾き)
N_se = N_panel  # 過積載100%枚数40枚
hoge[4] = 1  # 南西設置の時の判別(hoge=[0,0,1,0,0])

# #====両面受光_bifacial(both_side_light_reception_photovoltaics)(仮)東西設置==========
a_be = 90  # Azimuth(方位角)
theta_a_be = Tilt_angle  # Tilt_angl = 0(傾き)
N_be = N_panel
hoge[5] = 1  # 両面受光東西設置の時の判別(hoge =[0,0,0,1,0])

# #====両面受光_bifacial(both_side_light_reception_photovoltaics)(仮)南北設置==========
a_bs = 180  # Azimuth(方位角)
theta_a_bs = Tilt_angle  # Tilt_angl = 0(傾き)
N_bs = N_panel
hoge[6] = 1  # 両面受光南北設置の時の判別(hoge =[0,0,0,0,1])

# =====================================================================================

# ##=================place============================================================
# #naha ==============================================================
# phi = 26.207 # latitude
# lamda = 127.685 # longitude
# # 1990~2009_csv_data(NAHA) -> list H,Hb,Hd ===================
# H_data  = pd.read_csv('./H/H.csv', names = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24])
# # H_data = list(H_data.as_matrix().tolist())                                    #as_matrix()はpython3.7から非推奨#.valueに置き換える
# H_data = list(H_data.values.tolist())

# #fukui =============================================================
# phi = 36.033 # latitude
phi = 36.05833
# lamda = 136.133 # longitude
lamda = 136.225
# 1990~2009_csv_data(fukui) -> list H,Hb,Hd ==================
H_data = pd.read_csv('pv_create/H/H_imajyo.csv', names=[
                     1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24])
# H_data = list(H_data.as_matrix().tolist())
H_data = list(H_data.values.tolist())

# #====date====================================================================
# 一番日射量が多い日(年は閏年ではない年にする)
date_fine = dt.date(2019, 6, 2)
# 一番変動が多い日
date_fluctuation = dt.date(2019, 1, 19)
# 一番変動が少ない日
date_cloudy = dt.date(2019, 1, 8)
# ======================================================================================
dn_fi = (date_fine - dt.date(2019, 1, 1)).days + \
    1                                     # 正月から何日目かを求める
dn_fl = (date_fluctuation - dt.date(2019, 1, 1)).days + 1
dn_cl = (date_cloudy - dt.date(2019, 1, 1)).days + 1

Ppv_N_s = []
Ppv_N_w = []
Ppv_N_sw = []
Ppv_N_be = []
Ppv_N_bs = []

# 　全天 ###########################################################
H = []
Hb = []
Hd = []

H.append(H_data[0])
Hb.append(H_data[1])
Hd.append(H_data[2])

i = 9
while i <= 3284:  # 9 x 365 - 1 #365日分の9要素で配列番号は0から
    if i % 9 == 0:
        H.append(H_data[i])  # 水平面全天
        Hb.append(H_data[i + 1])  # 直達成分
        Hd.append(H_data[i + 2])  # 散乱成分
    i += 1

# すべての要素に対して0.01MJ/m^2をJ/m^2にするために0.01をかけて10^6をかけて3600で割って電力量[J*s]=[W*s]にしている
H = [[col * 0.01 * 10 ** 6 / 3600 for col in row] for row in H]
Hb = [[col * 0.01 * 10 ** 6 / 3600 for col in row] for row in Hb]
Hd = [[col * 0.01 * 10 ** 6 / 3600 for col in row] for row in Hd]


# parameters ===========================================================================
# 1枚あたりの設備容量：225W
p = 0.2  # albedo
omega = 2 * math.pi / 365
# Np = 20
# Ns = 20
KI = 0.0032  # 温度に対する短絡電流の係数K1
Temp = 25  # 温度
Gn = 1000  # 式(14)に登場するhn
Iph_cell = 8.214  # 光電流
Isc_n = 8.91  # 短絡電流
Voc_n = 37.27  # 開放電圧
c = 1.3  # 理想係数
k = 1.38064852 * 10 ** (-23)  # ボルツマン定数
q = 1.60217662 * 10 ** (-19)  # 電気素量
Eg = 1.12  # エネルギーギャップ
Vpv = 29.59  # PV出力電流

# main ========================================================================
tau = list(range(24))  # 式(3)
alpha = list(range(24))  # 式(5)
theta_z = list(range(24))  # pp2天頂角
A = list(range(24))  # 太陽の方位角A[rad]
As = list(range(24))  # 太陽の方位角sinA成分
Ac = list(range(24))  # 太陽の方位角cosA成分
theta = list(range(24))  # pp2パネルへの入射角
hb = copy.deepcopy(Hb)  # アドレスも変えるcopy
hr = copy.deepcopy(H)
hd = copy.deepcopy(Hd)
h = copy.deepcopy(H)
Iph = list(range(24))  # 光電流
Temp = list(range(24))  # 温度
I0_n = list(range(24))  # 式(15)のI0_n
I0 = list(range(24))  # ダイオード逆方向飽和電流
Ipv = list(range(24))  # PV出力電流
Wpv = list(range(24))
# ==============================================
Wpv_s_fi = list(range(24))
Wpv_s_fl = list(range(24))
Wpv_s_cl = list(range(24))
Wpv_w_fi = list(range(24))
Wpv_w_fl = list(range(24))
Wpv_w_cl = list(range(24))
Wpv_sw_fi = list(range(24))
Wpv_sw_fl = list(range(24))
Wpv_sw_cl = list(range(24))
Wpv_e_fi = list(range(24))
Wpv_e_fl = list(range(24))
Wpv_e_cl = list(range(24))
Wpv_se_fi = list(range(24))
Wpv_se_fl = list(range(24))
Wpv_se_cl = list(range(24))
Wpv_be_fi = list(range(24))
Wpv_be_fl = list(range(24))
Wpv_be_cl = list(range(24))
Wpv_bs_fi = list(range(24))
Wpv_bs_fl = list(range(24))
Wpv_bs_cl = list(range(24))

# # # ==========================================
if hoge[0] == 1:
    Wpv_s_fi = Power(N_s, N_s, a_s, theta_a_s, dn_fi)
    Wpv_s_fi = copy.deepcopy(Wpv_s_fi)
    Wpv_s_fl = Power(N_s, N_s, a_s, theta_a_s, dn_fl)
    Wpv_s_fl = copy.deepcopy(Wpv_s_fl)
    Wpv_s_cl = Power(N_s, N_s, a_s, theta_a_s, dn_cl)
    Wpv_s_cl = copy.deepcopy(Wpv_s_cl)
if hoge[1] == 1:
    Wpv_w_fi = Power(N_w, N_w, a_w, theta_a_w, dn_fi)
    Wpv_w_fi = copy.deepcopy(Wpv_w_fi)
    Wpv_w_fl = Power(N_w, N_w, a_w, theta_a_w, dn_fl)
    Wpv_w_fl = copy.deepcopy(Wpv_w_fl)
    Wpv_w_cl = Power(N_w, N_w, a_w, theta_a_w, dn_cl)
    Wpv_w_cl = copy.deepcopy(Wpv_w_cl)
if hoge[2] == 1:
    Wpv_sw_fi = Power(N_sw, N_sw, a_sw, theta_a_sw, dn_fi)
    Wpv_sw_fi = copy.deepcopy(Wpv_sw_fi)
    Wpv_sw_fl = Power(N_sw, N_sw, a_sw, theta_a_sw, dn_fl)
    Wpv_sw_fl = copy.deepcopy(Wpv_sw_fl)
    Wpv_sw_cl = Power(N_sw, N_sw, a_sw, theta_a_sw, dn_cl)
    Wpv_sw_cl = copy.deepcopy(Wpv_sw_cl)
if hoge[3] == 1:
    Wpv_e_fi = Power(N_e, N_e, a_e, theta_a_e, dn_fi)
    Wpv_e_fi = copy.deepcopy(Wpv_e_fi)
    Wpv_e_fl = Power(N_e, N_e, a_e, theta_a_e, dn_fl)
    Wpv_e_fl = copy.deepcopy(Wpv_e_fl)
    Wpv_e_cl = Power(N_e, N_e, a_e, theta_a_e, dn_cl)
    Wpv_e_cl = copy.deepcopy(Wpv_e_cl)
if hoge[4] == 1:
    Wpv_se_fi = Power(N_se, N_se, a_se, theta_a_se, dn_fi)
    Wpv_se_fi = copy.deepcopy(Wpv_se_fi)
    Wpv_se_fl = Power(N_se, N_se, a_se, theta_a_se, dn_fl)
    Wpv_se_fl = copy.deepcopy(Wpv_se_fl)
    Wpv_se_cl = Power(N_se, N_se, a_se, theta_a_se, dn_cl)
    Wpv_se_cl = copy.deepcopy(Wpv_se_cl)
if hoge[5] == 1:
    Wpv_be_fi = Power2(N_be, N_be, a_be, theta_a_be, dn_fi)
    Wpv_be_fi = copy.deepcopy(Wpv_be_fi)
    Wpv_be_fl = Power2(N_be, N_be, a_be, theta_a_be, dn_fl)
    Wpv_be_fl = copy.deepcopy(Wpv_be_fl)
    Wpv_be_cl = Power2(N_be, N_be, a_be, theta_a_be, dn_cl)
    Wpv_be_cl = copy.deepcopy(Wpv_be_cl)
if hoge[6] == 1:
    Wpv_bs_fi = Power2(N_bs, N_bs, a_bs, theta_a_bs, dn_fi)
    Wpv_bs_fi = copy.deepcopy(Wpv_bs_fi)
   # print(sum(Wpv_bs_fi))
    Wpv_bs_fl = Power2(N_bs, N_bs, a_bs, theta_a_bs, dn_fl)
    Wpv_bs_fl = copy.deepcopy(Wpv_bs_fl)
    Wpv_bs_cl = Power2(N_bs, N_bs, a_bs, theta_a_bs, dn_cl)
    Wpv_bs_cl = copy.deepcopy(Wpv_bs_cl)


# =====================graf===================================================
# ======快晴日===================================================
hour = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
        14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
fig = plt.figure()
ax = fig.add_subplot(111)
ax.set_xlim(0, 23)
ax.set_ylim(0, 225)
plt.xticks([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
           14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24])
font = {'family': 'IPAexGothic'}
plt.plot(hour, Wpv_s_fi, color='blue', label=r"片面受光 真南設置")
plt.plot(hour, Wpv_w_fi, color='violet', label=r"片面受光 西側設置")
plt.plot(hour, Wpv_sw_fi, color='red', label=r"片面受光 南西設置")
plt.plot(hour, Wpv_e_fi, color='cyan', label=r"片面受光 東側設置")
plt.plot(hour, Wpv_se_fi, color='magenta', label=r"片面受光 南東設置")
plt.plot(hour, Wpv_be_fi, color='Green', label=r"両面受光 東西設置")
plt.plot(hour, Wpv_bs_fi, color='orange', label=r"両面受光 南北設置")
plt.xlabel(r"時間 [h]", fontsize=10)
plt.ylabel(r"電力量[Wh]", fontsize=10)
plt.title(date_fine.strftime('%m月%d日')+'の各時間当たりの発電量')
plt.legend(fontsize=10)
plt.grid()
# ===================================================================
# ======変動の多い日===================================================
# hour=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]
# fig = plt.figure()
# ax = fig.add_subplot(111)
# ax.set_xlim(0, 23)
# ax.set_ylim(0, 225)
# plt.xticks([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
#            14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24])
# font = {'family': 'IPAexGothic'}
# plt.plot(hour, Wpv_s_fl, color='blue', label=r"片面受光 真南設置 N=40")
# plt.plot(hour, Wpv_w_fl, color='violet', label=r"片面受光 西側設置 N=40")
# plt.plot(hour, Wpv_sw_fl, color='red', label=r"片面受光 南西設置 N=40")
# plt.plot(hour, Wpv_e_fl, color='cyan', label=r"片面受光 東側設置 N=40")
# plt.plot(hour, Wpv_se_fl, color='magenta', label=r"片面受光 南東設置 N=40")
# plt.plot(hour, Wpv_be_fl, color='Green', label=r"両面受光 東西設置 N=40")
# plt.plot(hour, Wpv_bs_fl, color='orange', label=r"両面受光 南北設置 N=40")
# plt.xlabel(r"時間 [h]", fontsize=10)
# plt.ylabel(r"電力量[W]", fontsize=10)
# plt.title('変動の多い日('+date_fluctuation.strftime('%m/%d')+')の各時間当たりの発電量')
# plt.legend(fontsize=10)
# plt.grid()
# ===================================================================
# ======曇りの日(変動の少ない日)===================================================
# hour=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23]
# fig = plt.figure()
# ax = fig.add_subplot(111)
# ax.set_xlim(0, 23)
# ax.set_ylim(0, 225)
# plt.xticks([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
#            14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24])
# #font = {'family': 'IPAexGothic'}
# plt.plot(hour, Wpv_s_cl, color='blue', label=r"片面受光 真南設置 N=40")
# plt.plot(hour, Wpv_w_cl, color='violet', label=r"片面受光 西側設置 N=40")
# plt.plot(hour, Wpv_sw_cl, color='red', label=r"片面受光 南西設置 N=40")
# plt.plot(hour, Wpv_e_cl, color='cyan', label=r"片面受光 東側設置 N=40")
# plt.plot(hour, Wpv_se_cl, color='magenta', label=r"片面受光 南東設置 N=40")
# plt.plot(hour, Wpv_be_cl, color='Green', label=r"両面受光 東西設置 N=40")
# plt.plot(hour, Wpv_bs_cl, color='orange', label=r"両面受光 南北設置 N=40")
# plt.xlabel(r"時間 [h]", fontsize=10)
# plt.ylabel(r"電力量[W]", fontsize=10)
# plt.title('変動の少ない日('+date_cloudy.strftime('%m/%d')+')の各時間当たりの発電量')
# plt.legend(fontsize=10)
# plt.grid()
# ===================================================================

plt.show()

print("終了しました。\n")
