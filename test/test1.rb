$: << ".."; require 'ruic'; RUIC do

metadata 'MetaData.xml'                           # optional
app = uia 'projects/BMW_Cluster/BMW_Cluster.uia'  # required before other commands

assert app['logic']
assert app['logic'].datamodel=='{output=output}'

main = app['main']
assert main == app.main_presentation
assert main.filename == 'BMW_Cluster.uip'

assert !app['beejonkers']

sm = app/'main:Scene.ClassicContent.ClassicContent.SimpleMedia'
assert sm.name == 'SimpleMedia'

sm2 = main/'Scene.ClassicContent.ClassicContent.SimpleMedia'
assert sm==sm2

assert sm.component == (main/'Scene.ClassicContent.ClassicContent')
assert sm.component.slides.length==2
assert sm.component.slides[2].name == 'CarStatus'
assert sm.component.slides[0].name == 'Master Slide'
assert sm.component.slides['CarStatus'].name == 'CarStatus'

assert sm[0].endtime==250
assert sm[1].endtime==500
assert sm['SimpleMedia'].endtime==500
assert sm['CarStatus'  ].endtime==250

assert sm.position.linked?
assert !sm.endtime.linked?
assert sm.endtime.values       == [500,250]
assert sm.endtime.values(true) == [250,500,250]

assert sm.endtime[1]==500
assert sm.endtime['SimpleMedia']==500
assert sm.endtime['CarStatus'  ]==250

sm.endtime['CarStatus'] = 750
assert sm.endtime['SimpleMedia']==500
assert sm.endtime['CarStatus'  ]==750
assert sm['SimpleMedia'].endtime==500
assert sm['CarStatus'  ].endtime==750

sm['CarStatus'].endtime = 50
assert sm.endtime['CarStatus']==50
assert sm['CarStatus'].endtime==50

sm.endtime = 100
assert sm.endtime[0]==100
assert sm.endtime[1]==100
assert sm.endtime[2]==100

assert sm.scale[0].y == 2.88
assert sm.position[0].x==0

end