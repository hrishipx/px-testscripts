
cat << eof | kubectl apply -f -
apiVersion: volumesnapshot.external-storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: prod-db-snapshots
  namespace: default
  annotations:
    portworx/snapshot-type: local
    portworx/tier: prod
    portworx/name: db
spec:
  persistentVolumeClaimName: wp-pv-claim
eof

cat << a | kubectl apply -f -
apiVersion: volumesnapshot.external-storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: prod-db-snapshots-incorrectclaim-name
  namespace: default
  annotations:
    portworx/snapshot-type: local
    portworx/tier: prod
    portworx/name: db
spec:
  persistentVolumeClaimName: incorrectClaimName #Should not create a volumesnapshotdata object since there is no claim that matches.
a

cat << b | kubectl apply -f -
apiVersion: volumesnapshot.external-storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: prod-db-snapshots
  namespace: default
  annotations:
    portworx/snapshot-type: local
    portworx/tier: prod
    portworx/name: db
spec:
  persistentVolumeClaimName: wp-pv-claim #Editing the same volumesnapshot doesnt have any effect. 
b

cat << b | kubectl apply -f -
apiVersion: volumesnapshot.external-storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: prod-db-snapshots-corrected
  namespace: default
  annotations:
    portworx/snapshot-type: local
    portworx/tier: prod
    portworx/name: db
spec:
  persistentVolumeClaimName: wp-pv-claim #This should create atleast 3 snapshots, 1 Postgres, 1 wp-pv-claim and 1 for mysql (Look at the shell scripts in this folder)
b

cat << x | kubectl apply -f -
apiVersion: volumesnapshot.external-storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: prod-db-snapshots-1
  namespace: default
  annotations:
    portworx/snapshot-type: local
    portworx/tier: prod
    portworx/name: db
spec:
  persistentVolumeClaimName: postgres-data # Just using a different PVC name. 
x


cat << x | kubectl apply -f -
apiVersion: volumesnapshot.external-storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: prod-db-snapshots-allpvc
  namespace: default
  annotations:
    portworx/snapshot-type: local
    portworx/namespace: default
spec:
  persistentVolumeClaimName: postgres-data # All PVCs in the namespace. 
x