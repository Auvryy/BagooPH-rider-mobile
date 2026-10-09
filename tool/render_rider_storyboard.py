#!/usr/bin/env python3
"""Draw a documentation storyboard with clearly labelled synthetic values."""
from pathlib import Path
import argparse,html,subprocess,json

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/design/visuals'
TOKENS=json.loads((ROOT/'docs/design/tokens.json').read_text())
PALETTE=TOKENS['light'];RADII=TOKENS['geometry']['radii']
INK=PALETTE['ink'];MUTED=PALETTE['muted'];RED=PALETTE['accent'];DARK=PALETTE['accent_text'];ROSE=PALETTE['selection'];BG=PALETTE['canvas']
def text(x,y,s,size=16,weight=400,color=INK,anchor='start'):
 return f'<text x="{x}" y="{y}" font-family="Plus Jakarta Sans, sans-serif" font-size="{size}" font-weight="{weight}" fill="{color}" text-anchor="{anchor}">{html.escape(s)}</text>'
def rect(x,y,w,h,fill='#FFFFFF',stroke='none',r=RADII['surface']):
 return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}"/>'
def line(x,y,X,Y,c='#E2E8F0',width=1):
 return f'<path d="M{x} {y} L{X} {Y}" stroke="{c}" stroke-width="{width}" fill="none"/>'
def button(x,y,w,label,primary=False):
 return rect(x,y,w,52,RED if primary else '#FFFFFF','none' if primary else '#64748B',r=RADII['control'])+text(x+w/2,y+32,label,14,600,'#FFFFFF' if primary else INK,'middle')
def badge(x,y,label,fill=ROSE,color=DARK,w=114):
 return rect(x,y,w,28,fill)+text(x+12,y+19,label,12,600,color)
def cube(x,y,scale=1):
 return f'<g transform="translate({x} {y}) scale({scale})"><path d="M0 10 20 0 40 10 20 21Z M0 10v24l20 11 20-11V10 M20 21v24 M10 5l20 10" stroke="{DARK}" stroke-width="2" fill="none" stroke-linejoin="round"/></g>'
def nav(active=0):
 s=rect(8,676,336,76,'#FFFFFF','#E2E8F0')
 labels=['Tasks','Trips','Messages','Profile']
 for i,label in enumerate(labels):
  x=50+i*84;c=DARK if i==active else MUTED
  if i==active:s+=rect(x-31,684,62,36,ROSE)
  if i==0:s+=f'<path d="M{x-9} 698h18v12h-18z M{x-9} 698l9-5 9 5 M{x} 698v12" fill="none" stroke="{c}" stroke-width="1.8"/>'
  elif i==1:s+=f'<path d="M{x-9} 699h18 M{x-9} 705h18 M{x-9} 711h12" fill="none" stroke="{c}" stroke-width="1.8"/>'
  elif i==2:s+=f'<path d="M{x-10} 697h20v13h-13l-7 5z" fill="none" stroke="{c}" stroke-width="1.8"/>'
  else:s+=f'<circle cx="{x}" cy="699" r="4" stroke="{c}" fill="none"/><path d="M{x-9} 713q0-10 9-10t9 10" stroke="{c}" fill="none"/>'
  s+=text(x,738,label,11,600 if i==active else 500,c,'middle')
 return s
def header(title,sub=None,back=False):
 s=text(25,31,'9:41',13,600)+text(327,31,'•••',13,600,INK,'end')
 if back:s+=f'<path d="M31 60 21 70 31 80" fill="none" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>'
 else:s+=text(22,78,'BagooPH',20,700)
 if back:s+=text(330,78,'Help',13,600,MUTED,'end')
 s+=text(22,124,title,25,600)
 if sub:s+=text(22,149,sub,13,500,MUTED)
 return s
def field(y,label,value='',password=False):
 return text(22,y,label,14,600)+rect(22,y+12,308,52,'#FFFFFF','#64748B',r=RADII['control'])+text(36,y+45,'••••••••••••' if password else value,16,400,MUTED)
def map_block(y,h=148):
 s=rect(22,y,308,h,'#F3F1EC','#CBD5E1',r=RADII['map'])
 s+=f'<g clip-path="url(#mapclip-{y})">'
 for x in range(38,340,58):s+=line(x,y-10,x+40,y+h+10,'#FFFFFF',11)+line(x,y-10,x+40,y+h+10,'#D3DADD',1)
 for k in [40,91,131]:s+=line(10,y+k,350,y+k-20,'#FFFFFF',12)+line(10,y+k,350,y+k-20,'#D3DADD',1)
 s+=rect(254,y+65,40,32,'#DDE7DA',r=3)
 s+='</g>'
 s+=f'<defs><clipPath id="mapclip-{y}">{rect(22,y,308,h,r=RADII['map'])}</clipPath></defs>'
 s+=f'<path d="M176 {y+92}c-20-25-24-37-24-48a24 24 0 1 1 48 0c0 11-4 23-24 48Z" fill="{RED}" stroke="white" stroke-width="2"/><circle cx="176" cy="{y+43}" r="7" fill="white"/>'
 s+=rect(35,y+12,94,25,'#FFFFFF')+text(47,y+29,'Saved stop',11,600)
 s+=text(314,y+h-9,'Map attribution',9,400,MUTED,'end')
 return s
def build(kind):
 s=rect(0,0,352,760,BG,'#CBD5E1',28)+rect(123,7,106,10,INK,r=5)
 if kind=='login':
  s+=header('Sign in','Your rider workspace')
  s+=rect(22,184,308,110,ROSE)+cube(246,203,1.25)+text(38,215,'One parcel.',18,600)+text(38,243,'A clear next step.',18,600)+text(38,272,'Pickup and delivery in one app.',12,500,MUTED)
  s+=field(337,'Email address','rider@example.test')+field(435,'Password',password=True)
  s+=rect(23,523,18,18,'#FFFFFF','#64748B',4)+text(52,537,'Remember email',13,500)+text(330,575,'Forgot password?',14,600,DARK,'end')
  s+=button(22,603,308,'Sign in',True)+text(176,695,'Apply as a rider',14,600,DARK,'middle')
 elif kind=='home':
  s+=header('Your tasks','Assigned hub')
  s+=f'<path d="M160 76v-7a8 8 0 0 1 16 0v7l4 5h-24z M165 85h6" stroke="{INK}" stroke-width="1.8" fill="none" stroke-linejoin="round"/>'
  s+=rect(208,48,122,48,'#FFFFFF','#CBD5E1')+text(220,78,'On duty',12,600)+rect(282,60,36,24,RED,r=12)+f'<circle cx="306" cy="72" r="9" fill="white"/>'
  s+=rect(22,171,102,40,ROSE)+text(73,196,'Pickups · 3',13,600,DARK,'middle')+text(170,196,'Delivery',13,500,MUTED,'middle')+text(287,196,'Available',13,500,MUTED,'middle')
  s+=rect(22,233,308,230,'#FFFFFF','#E2E8F0')+rect(22,233,4,230,RED,r=2)
  s+=badge(39,250,'Collect from seller',w=163)+text(39,309,'Example seller',20,600)+text(39,337,'Example collection address',14,400,MUTED)+text(39,367,'Parcel DEMO-04821',13,500,MUTED)
  s+=button(39,392,274,'Open Stop Mode',True)
  s+=text(22,502,'Remaining pickups',17,600)
  for y,label,ref in [(541,'Bring to origin hub','DEMO-04822'),(607,'Collect from seller','DEMO-04823')]:
   s+=text(22,y,label,15,600)+text(22,y+23,ref,12,500,MUTED)+text(322,y+10,'›',25,400,MUTED)+line(22,y+37,330,y+37)
  s+=nav(0)
 elif kind=='stop':
  s+=header('Your selected stop','DEMO-04821 · Delivery',True)+badge(22,173,'Out for delivery',w=144)
  s+=text(22,226,'Example recipient',21,600)+text(22,252,'Example address · Unit 2',15,400,MUTED)
  s+=text(22,280,'Blue entrance beside the bakery',13,500)+text(22,303,'Open entrance instructions',12,600,DARK)
  s+=map_block(326,138)
  for i,l in enumerate(['Directions','Call','Message']):s+=button(22+104*i,476,100,l)
  s+=text(22,565,'Parcel location',12,500,MUTED)+text(22,589,'Top box · Right',16,600)
  s+=text(330,565,'Cash due',12,500,MUTED,'end')+text(330,594,'₱685.00',24,600,INK,'end')
  s+=button(22,614,308,'Review handoff',True)+nav(0)
 elif kind=='finder':
  s+=header('Parcel Finder','Organization for your pickups',True)
  s+=badge(22,171,'DEMO-04821',w=135)
  s+=rect(22,216,308,252,'#FFFFFF','#E2E8F0')+text(176,247,'Top box',16,600,INK,'middle')
  s+=rect(47,270,122,118,'#FFFFFF','#64748B')+rect(183,270,122,118,ROSE,DARK)
  s+=cube(86,292,.9)+cube(222,292,.9)+text(108,367,'Left',14,600,INK,'middle')+text(244,367,'Right · Selected',12,600,DARK,'middle')
  s+=rect(47,402,258,45,'#FFFFFF','#64748B')+text(176,430,'Bag 2',14,600,INK,'middle')
  s+=text(22,511,'Selected parcel',12,500,MUTED)+text(22,539,'DEMO-04821',18,600)+text(22,568,'Top box · Right compartment',14,500,MUTED)
  s+=button(22,605,308,'Save parcel location',True)+nav(0)
 elif kind=='proof':
  s+=header('Delivery evidence','Step 1 of 3 · DEMO-04821',True)
  s+=field(190,'Recipient / relationship','Example recipient')
  s+=text(22,290,'Proof photo',14,600)+rect(22,307,308,178,'#F1F5F9','#64748B')
  s+=rect(108,343,136,96,'#FFFFFF','#CBD5E1')+cube(143,365,1.4)+text(176,467,'Illustrative sample image',12,500,MUTED,'middle')
  s+=button(22,503,148,'Replace photo')+button(182,503,148,'Remove')
  s+=text(22,591,'Review the handoff before submission.',13,500,MUTED)
  s+=button(22,661,308,'Continue',True)+text(176,741,'Cancel returns to your parcel',12,500,MUTED,'middle')
 elif kind=='cash':
  s+=header('Cash at delivery','Step 2 of 3 · DEMO-04821',True)
  s+=rect(22,182,308,125,'#FFFFFF','#E2E8F0')+text(38,214,'AMOUNT DUE',12,600,MUTED)+text(38,267,'₱685.00',36,600)+text(313,285,'COD',12,600,MUTED,'end')
  s+=field(354,'Cash tendered','₱1,000.00')
  s+=rect(22,452,308,105,ROSE)+text(38,482,'Correct change',13,500,MUTED)+text(38,522,'₱315.00',30,600)
  s+=text(22,598,'Amount due remains ₱685.00.',14,500,MUTED)+text(22,623,'Cash problem? Get the next step.',13,600,DARK)
  s+=button(22,661,308,'Continue to review',True)
 elif kind=='chat':
  s+=header('Example recipient','DEMO-04821 · Delivery',True)
  s+=rect(22,170,308,60,ROSE)+text(38,195,'Saved buyer destination',14,600)+text(38,216,'Return to task ›',12,600,DARK)
  s+=rect(22,260,250,75,'#FFFFFF','#E2E8F0')+text(36,287,'The entrance is beside',15,400)+text(36,310,'the bakery. Unit 2.',15,400)
  s+=rect(71,366,259,67,ROSE)+text(85,395,'Thank you. I will check it.',14,400)
  s+=text(176,469,'Sample conversation',12,500,MUTED,'middle')
  s+=rect(22,620,308,100,'#FFFFFF','#64748B')+text(36,650,'Write a message…',15,400,MUTED)+rect(214,668,102,48,RED)+text(265,697,'Send',13,600,'#FFFFFF','middle')
 elif kind=='profile':
  s+=header('Profile')
  s+=rect(22,160,308,104)+f'<circle cx="61" cy="210" r="24" fill="{ROSE}"/>'+text(61,216,'DR',15,600,DARK,'middle')
  s+=text(102,194,'Demo rider',17,600)+text(102,217,'rider@example.test',12,500,MUTED)
  s+=text(102,241,'Account details',12,600,DARK)+text(309,216,'›',24,400,MUTED)
  s+=rect(22,284,308,58)+text(42,319,'Settings',16,500)+text(309,319,'›',24,400,MUTED)
  s+=text(24,378,'Work information',13,500,MUTED)+rect(22,394,308,116)
  for y,label in [(429,'Assignment'),(487,'Vehicle and credentials')]:
   s+=text(42,y,label,16,500)+text(309,y,'›',24,400,MUTED)
  s+=line(42,452,312,452)+nav(3)

 return s

SCENES=[('P01','Sign in','login'),('P05','Home / Tasks','home'),('P06','Stop Mode','stop'),('P08','Parcel Finder','finder'),('P11','Evidence review','proof'),('P12','Cash review','cash'),('P22','Conversation','chat'),('P25','Profile','profile')]
def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--font-file');parser.add_argument('--png',action='store_true');args=parser.parse_args()
 OUT.mkdir(parents=True,exist_ok=True)
 head='<svg xmlns="http://www.w3.org/2000/svg" width="1760" height="1910" viewBox="0 0 1760 1910"><title>BagooPH Rider design storyboard</title><desc>Eight illustrative compositions with synthetic values. This is design documentation, not a running app or recorded operational result.</desc>'
 s=head+rect(0,0,1760,1910,'#F1F2F5',r=0)+text(64,68,'BagooPH Rider',34,700)+text(64,111,'A clear next step, wherever the work takes you.',19,400,MUTED)+text(64,147,'Illustrative compositions · Sample values · Planned frontend design',13,600,MUTED)
 for idx,(ident,title,kind) in enumerate(SCENES):
  x=64+(idx%4)*420;y=206+(idx//4)*841
  s+=text(x,y-20,ident+'  /  '+title,16,600)+f'<g transform="translate({x},{y})">'+build(kind)+'</g>'
  single='<svg xmlns="http://www.w3.org/2000/svg" width="352" height="760" viewBox="0 0 352 760"><title>'+html.escape(title)+' planned composition</title><desc>Illustrative screen with sample values; no native implementation.</desc>'+build(kind)+'</svg>'
  (OUT/(ident.lower()+'.svg')).write_text(single)
 s+=text(64,1872,'48 full native views · 8 external views · 20 app overlays · 4 stable destinations',14,600,MUTED)+'</svg>'
 (OUT/'storyboard.svg').write_text(s)
 if args.png:
  cmd=['resvg']
  if args.font_file:cmd+=['--use-font-file',args.font_file]
  cmd+=[str(OUT/'storyboard.svg'),str(OUT/'storyboard.png')]
  subprocess.run(cmd,check=True)
 print('Created eight editable screen SVGs and the labelled storyboard'+(' PNG.' if args.png else '.'))
if __name__=='__main__':main()
