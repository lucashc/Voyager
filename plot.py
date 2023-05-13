#%%
import matplotlib.pyplot as plt
import json
import pandas as pd
import numpy as np
from tqdm import tqdm

with open('sample_games/long_game.json') as f:
    data = json.load(f)
df = pd.DataFrame(data)

axs=[]
max_time = df['t'].max()

times = range(0, max_time, 1)

for t in tqdm(times):
    sub_df = df[df['t'] == t]
    players = sub_df[sub_df['ty']==0]
    us = sub_df[sub_df['username']=="OutLauz"]
    players = players[players['username']!="OutLauz"]
    bullets = sub_df[sub_df['ty']==1]
    cod = sub_df[sub_df['ty']=="cod"].iloc[0]
    fig, ax = plt.subplots(figsize=(10, 10))
    if cod['x']!=-1:
        circ = plt.Circle((cod['x'], cod['y']), cod['r'], color="#90ee90")
        ax.add_patch(circ)
    players = players[players['h']>0]
    col = ax.scatter(players['x'], players['y'], c=players['h'], s=100, vmin=0, vmax=100, cmap='coolwarm')   
    for i in range(len(players)):
        row = players.iloc[i]
        ax.annotate(int(row['id']), (row['x'], row['y']))
    ax.scatter(us['x'], us['y'], c=us['h'], s=300, vmin=0, vmax=100, cmap='coolwarm')
    ax.annotate("US", (us['x'], us['y']), color='y', fontsize=20)
    ax.scatter(bullets['x'], bullets['y'], c='k', s=50)
    # fig.colorbar(col)
    ax.axhline(0, color='k')
    ax.axvline(0, color='k')
    ax.axhline(500, color='k')
    ax.axvline(500, color='k')
    axs.append(ax)
    plt.xlim(-10, 510)
    plt.ylim(-10, 510)
    plt.axis('off')
    ax.set_title(f't={t}')
    plt.savefig(f'plots/{t}_long.png')
    plt.close()

import imageio
ims = [imageio.imread(f'plots/{t}_long.png') for t in times]
imageio.mimwrite("plots/animation_long.gif", ims)

# %%
