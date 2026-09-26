import json, re, os
import sys
S=sys.argv[1] if len(sys.argv) > 1 else './'
t=open(S+'shell_template.html').read()
t=t.replace('DEMO RPG KERTAS · TURN-BASED','RPG JELAJAH JAKARTA · ±1 JAM · PC &amp; HP').replace('Unduhan sekitar 18 MB','Unduhan sekitar 22 MB. Di HP: putar ke landscape')
t=t.replace('<span><kbd>X</kbd> <kbd>Esc</kbd> / klik kanan: batal</span>','<span><kbd>X</kbd>: dodge / batal</span><span><kbd>C</kbd>: menu</span><span>HP: joystick &amp; tombol layar</span>')
t=t.replace('<span><kbd>Z</kbd> <kbd>Spasi</kbd> / klik: pilih &amp; aksi</span>','<span><kbd>Z</kbd>: aksi, serang, parry</span>')
t=t.replace('navigasi</span>','jalan</span>')
js=open(S+'web/index.js').read()
cfgd=json.loads(re.search(r'const GODOT_CONFIG = (\{.*?\});', open(S+'web/index.html').read()).group(1))
cfgd['ensureCrossOriginIsolationHeaders']=False
wk={n:open(S+'web/'+n).read() for n in ('index.audio.worklet.js','index.audio.position.worklet.js')}
t=t.replace('__WASM_SIZE__',str(os.path.getsize(S+'web/index.wasm'))).replace('__PCK_SIZE__',str(os.path.getsize(S+'web/index.pck')))
t=t.replace('__WORKLETS__',json.dumps(wk)).replace('__CONFIG__',json.dumps(cfgd)).replace('__ENGINE_JS__',js)
open(S+'site/play.html','w').write(t)
print('built', len(t))
