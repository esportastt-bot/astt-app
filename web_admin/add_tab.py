import re

with open('index.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Add sheetjs script
if 'xlsx.full.min.js' not in html:
    html = html.replace('</head>', '    <script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>\n</head>')

# Add new tab
if 'id="tab-codes"' not in html:
    tab_html = '<li class="nav-item" role="presentation"><button class="nav-link" id="tab-codes" data-bs-toggle="tab" data-bs-target="#codes_admin" type="button"><i class="fas fa-key text-primary"></i> Codes</button></li>'
    html = html.replace('</ul>', f'    {tab_html}\n          </ul>')

# Add tab pane
if 'id="codes_admin"' not in html:
    pane_html = """
            <!-- ONGLET CODES -->
            <div class="tab-pane fade" id="codes_admin">
                <div class="card p-2">
                    <div class="card-header bg-dark text-primary"><i class="fas fa-key"></i> Distribution de Codes</div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label><i class="fas fa-file-excel text-success"></i> Fichier HelloAsso (Extract)</label>
                                <input type="file" id="helloAssoFile" class="form-control bg-dark text-white border-secondary" accept=".xlsx, .xls">
                                <small class="text-muted">Colonne I = E-mail / Colonne M = Tarif</small>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label><i class="fas fa-file-excel text-success"></i> Fichier Codes</label>
                                <input type="file" id="codesFile" class="form-control bg-dark text-white border-secondary" accept=".xlsx, .xls">
                                <small class="text-muted">Colonne B = Code / Colonne G = Date limite</small>
                            </div>
                        </div>
                        <div class="mt-3">
                            <button class="btn btn-primary btn-lg" onclick="generateDistribution()"><i class="fas fa-cogs"></i> Distribution Automatique</button>
                        </div>
                        
                        <div id="distributionPreview" class="mt-4 hidden">
                            <h4 class="text-info">Prévisualisation de la distribution</h4>
                            <div class="table-responsive">
                                <table class="table table-dark table-striped table-bordered mt-2">
                                    <thead>
                                        <tr>
                                            <th>E-mail de destination</th>
                                            <th>Code à attribuer</th>
                                            <th>Date limite</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody id="distributionTableBody">
                                        <!-- Généré dynamiquement -->
                                    </tbody>
                                </table>
                            </div>
                            <div class="mt-3 text-end">
                                <button class="btn btn-success btn-lg" onclick="saveDistributionToFirebase()"><i class="fas fa-cloud-upload-alt"></i> Envoyer vers l'application (Firebase)</button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
    """
    html = html.replace('<!--  ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?', pane_html + '\n            <!--  ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ? ?')

# Add JS logic
if 'function generateDistribution' not in html:
    js_html = """
    let generatedAssignments = [];

    function readXlsx(file) {
        return new Promise((resolve) => {
            const reader = new FileReader();
            reader.onload = (e) => {
                const data = e.target.result;
                const workbook = XLSX.read(data, {type: 'binary'});
                const firstSheetName = workbook.SheetNames[0];
                const worksheet = workbook.Sheets[firstSheetName];
                const json = XLSX.utils.sheet_to_json(worksheet, {header: 1});
                resolve(json);
            };
            reader.readAsBinaryString(file);
        });
    }

    async function generateDistribution() {
        const helloFile = document.getElementById('helloAssoFile').files[0];
        const codesFile = document.getElementById('codesFile').files[0];
        if(!helloFile || !codesFile) return alert("Veuillez sélectionner les 2 fichiers Excel d'abord.");

        try {
            const helloData = await readXlsx(helloFile);
            const codesData = await readXlsx(codesFile);

            let usersNeeded = {};
            // Start from 1 to skip header
            for(let i=1; i<helloData.length; i++) {
                let row = helloData[i];
                if(!row || row.length === 0) continue;
                let email = row[8]; // I
                let tarif = row[12]; // M
                if(email && tarif) {
                    let amountStr = tarif.toString().replace(',', '.').replace('', '').replace('€', '').trim();
                    let amount = parseFloat(amountStr);
                    if(!isNaN(amount) && amount > 0) {
                        let nbCodes = Math.floor(amount / 10);
                        if(nbCodes > 0) {
                            usersNeeded[email] = (usersNeeded[email] || 0) + nbCodes;
                        }
                    }
                }
            }

            let availableCodes = [];
            for(let i=1; i<codesData.length; i++) {
                let row = codesData[i];
                if(!row || row.length === 0) continue;
                let code = row[1]; // B
                let dateLimite = row[6] || ''; // G
                if(code) {
                    availableCodes.push({ code: code.toString().trim(), date: dateLimite.toString().trim() });
                }
            }

            generatedAssignments = [];
            let codeIndex = 0;
            for(let email in usersNeeded) {
                let needed = usersNeeded[email];
                for(let k=0; k<needed; k++) {
                    if(codeIndex < availableCodes.length) {
                        generatedAssignments.push({
                            id: Math.random().toString(36).substr(2, 9),
                            email: email.trim().toLowerCase(),
                            code: availableCodes[codeIndex].code,
                            dateLimite: availableCodes[codeIndex].date
                        });
                        codeIndex++;
                    }
                }
            }

            if (generatedAssignments.length === 0) {
                alert("Aucun code n'a pu être attribué. Vérifiez le format des fichiers (les colonnes doivent correspondre).");
            }

            renderDistributionTable();
            document.getElementById('distributionPreview').classList.remove('hidden');

        } catch (err) {
            console.error(err);
            alert("Erreur lors de la lecture des fichiers : " + err.message);
        }
    }

    function renderDistributionTable() {
        const tbody = document.getElementById('distributionTableBody');
        tbody.innerHTML = '';
        generatedAssignments.forEach((item, index) => {
            const tr = document.createElement('tr');
            tr.innerHTML = 
                <td><input type="text" class="form-control bg-dark text-white border-secondary" value="" onchange="updateAssignment('', 'email', this.value)"></td>
                <td><input type="text" class="form-control bg-dark text-info border-secondary" value="" onchange="updateAssignment('', 'code', this.value)"></td>
                <td><input type="text" class="form-control bg-dark text-white border-secondary" value="" onchange="updateAssignment('', 'dateLimite', this.value)"></td>
                <td><button class="btn btn-sm btn-danger" onclick="removeAssignment('')"><i class="fas fa-trash"></i></button></td>
            ;
            tbody.appendChild(tr);
        });
    }

    function updateAssignment(id, field, value) {
        const item = generatedAssignments.find(x => x.id === id);
        if(item) {
            item[field] = value;
        }
    }

    function removeAssignment(id) {
        generatedAssignments = generatedAssignments.filter(x => x.id !== id);
        renderDistributionTable();
    }

    async function saveDistributionToFirebase() {
        if(generatedAssignments.length === 0) return alert("Rien à envoyer.");
        if(!confirm("Êtes-vous sûr de vouloir envoyer ces " + generatedAssignments.length + " codes vers la base de données ? Les utilisateurs concernés les verront apparaître dans leur application.")) return;
        
        try {
            // Option 1 : Use existing UIDs if available.
            // Option 2 : We just search users by email
            const usersRef = db.collection('users');
            
            let successCount = 0;
            
            for(let item of generatedAssignments) {
                if(!item.email || !item.code) continue;
                
                let targetUid = null;
                // Search if user exists
                let q = await usersRef.where('email', '==', item.email).get();
                if(!q.empty) {
                    targetUid = q.docs[0].id;
                } else {
                    // Create a placeholder document with a new ID
                    let newDoc = usersRef.doc();
                    await newDoc.set({
                        email: item.email,
                        isStaff: false,
                        createdAt: firebase.firestore.FieldValue.serverTimestamp()
                    });
                    targetUid = newDoc.id;
                }
                
                // Add code to subcollection
                await usersRef.doc(targetUid).collection('codes').add({
                    code: item.code,
                    game: "Jeu (Date limite: " + item.dateLimite + ")",
                    isUsed: false,
                    createdAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                successCount++;
            }
            
            showToast(successCount + " code(s) distribué(s) avec succès !");
            document.getElementById('distributionPreview').classList.add('hidden');
            generatedAssignments = [];
            
        } catch (err) {
            console.error(err);
            alert("Erreur Firebase : " + err.message);
        }
    }
    """
    html = html.replace('</script>\n</body>', js_html + '\n</script>\n</body>')


with open('index.html', 'w', encoding='utf-8') as f:
    f.write(html)
