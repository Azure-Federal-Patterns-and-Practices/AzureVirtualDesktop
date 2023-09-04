param ApplicationGroupReferences array

var FixNames = [for ApplicationGroupReference in ApplicationGroupReferences: replace(replace(ApplicationGroupReference, 'resourcegroups', 'resourceGroups'), 'applicationgroups', 'applicationGroups')]

output ApplicationGroupReferences array = union(FixNames, [])
