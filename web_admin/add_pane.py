import re

with open('index.html', 'r', encoding='utf-8') as f:
    html = f.read()

# Add tab pane
if 'id="codes_admin"' not in html.split('myTabContent')[1]:
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
    html = html.replace('<div class="tab-content" id="myTabContent">', '<div class="tab-content" id="myTabContent">\n' + pane_html)

with open('index.html', 'w', encoding='utf-8') as f:
    f.write(html)
