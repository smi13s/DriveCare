(() => {
const $=id=>document.getElementById(id), esc=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const configured=window.DRIVECARE_SUPABASE_URL?.startsWith('https://') && !window.DRIVECARE_SUPABASE_ANON_KEY?.startsWith('YOUR_');
if(!configured || !window.supabase){$('setup').classList.remove('hide');return;}
const db=window.supabase.createClient(window.DRIVECARE_SUPABASE_URL,window.DRIVECARE_SUPABASE_ANON_KEY);
let user,profile,vehicles=[];
const show=(id,on)=>$(id).classList.toggle('hide',!on);
const msg=(text,error=false)=>{$('message').textContent=text;$('message').className='msg'+(error?' warn':'');};
const run=async fn=>{try{await fn();}catch(e){msg(e.message||String(e),true)}};
async function query(table,cols='*'){const {data,error}=await db.from(table).select(cols).order('created_at',{ascending:false});if(error)throw error;return data||[];}
async function save(table,data){const {error}=await db.from(table).insert(data);if(error)throw error;msg('Saved successfully.');await refresh();}
function items(el,rows,format){$(el).innerHTML=rows.length?rows.map(r=>`<div class="item">${format(r)}</div>`).join(''):'<p class="muted">Nothing here yet.</p>';}
function options(id,rows){$(id).innerHTML=rows.map(v=>`<option value="${esc(v.id)}">${esc(v.year+' '+v.make+' '+v.model)}</option>`).join('');}
async function refresh(){
const [vs,fs,ms,ss,rs]=await Promise.all([query('vehicles'),query('fleets'),query('membership_requests'),query('service_requests'),query('service_records')]);vehicles=vs;
items('vehicleList',vs,v=>`${esc(v.year)} ${esc(v.make)} ${esc(v.model)}<br><small>Mileage: ${esc(v.mileage??'Not provided')} • VIN: ${esc(v.vin||'Not provided')}</small>`);
items('fleetList',fs,f=>esc(f.company_name));$('vehicleFleet').innerHTML='<option value="">Personal vehicle</option>'+fs.map(f=>`<option value="${esc(f.id)}">${esc(f.company_name)}</option>`).join('');
options('memberVehicle',vs);options('serviceVehicle',vs);
items('memberList',ms,m=>`${esc(m.plan)} — <strong>${esc(m.status)}</strong><br><small>${esc(m.payment_term)} month payment option</small>`);
items('serviceList',ss,s=>`${esc(s.concern)} — <strong>${esc(s.status)}</strong>`);
items('recordList',rs,r=>`${esc(r.service_date)}: ${esc(r.description)}${r.mileage?' • '+esc(r.mileage)+' miles':''}`);
if(profile.role==='admin'){
show('admin',true);const [customers,allVehicles]=await Promise.all([query('profiles'),query('vehicles')]);
items('adminCustomers',customers,c=>`${esc(c.full_name||'Customer')}<br><small>${esc(c.phone||'')}</small>`);
items('adminVehicles',allVehicles,v=>`${esc(v.year)} ${esc(v.make)} ${esc(v.model)}`);
items('adminMembers',ms,m=>`${esc(m.plan)} — ${esc(m.status)} <button data-kind="member" data-id="${esc(m.id)}" data-status="approved">Approve</button> <button class="secondary" data-kind="member" data-id="${esc(m.id)}" data-status="declined">Decline</button>`);
items('adminServices',ss,s=>`${esc(s.concern)} — ${esc(s.status)} <button data-kind="service" data-id="${esc(s.id)}" data-status="contacted">Contacted</button> <button class="secondary" data-kind="service" data-id="${esc(s.id)}" data-status="scheduled">Scheduled</button>`);
}}
async function session(){const {data:{user:u}}=await db.auth.getUser();user=u;show('auth',!user);show('app',!!user);show('logout',!!user);if(!user)return;
const {data,error}=await db.from('profiles').select('*').eq('id',user.id).single();if(error)throw error;profile=data;
$('welcome').textContent='Welcome, '+(profile.full_name||user.email);$('role').textContent=profile.role==='admin'?'Administrator account':'Customer account';await refresh();}
$('signin').onclick=()=>run(async()=>{const {error}=await db.auth.signInWithPassword({email:$('email').value.trim(),password:$('password').value});if(error)throw error;await session();});
$('signup').onclick=()=>run(async()=>{if($('password').value.length<8)throw Error('Use a password with at least 8 characters.');const {error}=await db.auth.signUp({email:$('email').value.trim(),password:$('password').value,options:{data:{full_name:$('name').value.trim()}}});if(error)throw error;msg('Account created. Check your email to confirm your address, then sign in.');await session();});
$('logout').onclick=()=>run(async()=>{await db.auth.signOut();await session();});
for(const [id,table,convert] of [
['vehicleForm','vehicles',d=>({...d,year:Number(d.year),mileage:d.mileage?Number(d.mileage):null,vin:d.vin?.trim().toUpperCase()||null,fleet_id:d.fleet_id||null})],
['fleetForm','fleets',d=>d],
['memberForm','membership_requests',d=>({...d,payment_term:Number(d.payment_term)})],
['serviceForm','service_requests',d=>({...d,preferred_date:d.preferred_date||null})]]){
$(id).addEventListener('submit',e=>{e.preventDefault();run(async()=>{if(id==='memberForm'&&!vehicles.length)throw Error('Add a vehicle first.');const data=convert(Object.fromEntries(new FormData(e.target)));await save(table,{...data,owner_id:user.id});e.target.reset();});});}
$('admin').addEventListener('click',e=>{const b=e.target.closest('button[data-kind]');if(!b)return;run(async()=>{const table=b.dataset.kind==='member'?'membership_requests':'service_requests';const {error}=await db.from(table).update({status:b.dataset.status}).eq('id',b.dataset.id);if(error)throw error;msg('Status updated.');await refresh();});});
session().catch(e=>msg(e.message,true));
})();
