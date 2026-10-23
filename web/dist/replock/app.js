'use strict';
const exercises = {squats:{name:'Squat & unlock',reps:10,coins:20},jacks:{name:'Jump into it',reps:15,coins:30},march:{name:'Find your stride',reps:20,coins:20}};
let selected = 'squats', balance = 0, reps = 0, phase = 'ready', interval;
const stage = document.getElementById('demo-stage');
function render() {
  const task = exercises[selected];
  document.getElementById('demo-balance').textContent = balance;
  document.querySelectorAll('[data-challenge]').forEach(button => {button.setAttribute('aria-pressed', String(button.dataset.challenge === selected));button.disabled = phase === 'moving' || phase === 'unlocked';});
  const views = {
    ready:`<div class="demo-count">${task.reps}<small> REPS</small></div><div class="demo-stage-title">${task.name}</div><p class="demo-description">Finish a set. Earn ${task.coins} demo coins.</p><button class="button" id="demo-start">Play challenge walkthrough ↗</button>`,
    moving:`<div class="demo-count">${reps}<small> / ${task.reps}</small></div><div class="demo-progress"><div style="width:${reps/task.reps*100}%"></div></div><div class="demo-stage-title">One move at a time.</div><p class="demo-description">Illustration only. No camera is running.</p>`,
    earned:`<div class="demo-count">+${task.coins}<small> ✦</small></div><div class="demo-stage-title">YOU DID THAT.</div><p class="demo-description">Trade 10 demo coins for a 5-minute break.</p><button class="button" id="demo-redeem">Unlock a demo break · 10 coins ↗</button>`,
    unlocked:`<div class="demo-count">05:00</div><div class="demo-stage-title">A break with a boundary.</div><p class="demo-description">In RepLock, the selected app re-locks when time runs out. This demo doesn’t control your apps.</p><a class="button" href="#download">Make your next move ↗</a>`
  };
  stage.innerHTML = views[phase];
  document.getElementById('demo-start')?.addEventListener('click', () => {phase = 'moving'; reps = 0; render(); interval = setInterval(() => { reps++; if(reps >= task.reps){clearInterval(interval); balance += task.coins; phase = 'earned';} render();}, 320);});
  document.getElementById('demo-redeem')?.addEventListener('click', () => {if(balance < 10)return;balance-=10;phase='unlocked';render();});
}
function reset() {clearInterval(interval); balance = 0; reps = 0; phase = 'ready';render();}
document.querySelectorAll('[data-challenge]').forEach(button => button.addEventListener('click', () => {selected=button.dataset.challenge;reset();}));
document.getElementById('demo-reset').addEventListener('click', reset);
render();
fetch('downloads/release.json').then(r => {if(!r.ok)throw Error('Release unavailable'); return r.json();}).then(release => {
  document.getElementById('apk-meta').textContent = `Version ${release.version} · Android ${release.minAndroid}+ · ARM64 · ${(release.variants[0].bytes/1024/1024).toFixed(1)} MB`;
  document.getElementById('apk-checksum').textContent = `ARM64 SHA-256: ${release.variants[0].sha256}`;
}).catch(() => {});
fetch('launch.json').then(r => r.json()).then(launch => {
  if (!/^https:\/\/(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)[\w-]{11}$/.test(launch.youtubeUrl || '')) return;
  const link = document.getElementById('youtube-link');link.href=launch.youtubeUrl;link.hidden=false;
}).catch(() => {});
