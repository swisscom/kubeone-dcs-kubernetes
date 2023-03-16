vcd_api_url      = "https://vcd-pod-bravo.swisscomcloud.com/api"
vcd_api_username = "api_vcd_my_username"
vcd_api_password = "my_password"

vcd_org_name    = "PRO-0123456789"
vcd_vdc_name    = "my-data-center"
vcd_edgegateway = "PRO-0123456789-my-gateway"

kubeapi_hostname            = "my-kubernetes.my-domain.com"   # adjust to your domain/hostname, make sure you have setup a DNS *A* record beforehand
apiserver_alternative_names = ["my-kubernetes.my-domain.com"] # adjust to your domain/hostname, make sure you have setup a DNS *A* record beforehand

control_plane_disk_storage_profile = "Ultra Fast Storage A with Backup" # adjust to a storage profile of your choice, see "VCD UI -> Data Centers -> Storage -> Storage Policies"
worker_disk_storage_profile        = "Ultra Fast Storage A"             # adjust to a storage profile of your choice, see "VCD UI -> Data Centers -> Storage -> Storage Policies"