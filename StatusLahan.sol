// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StatusLahan {

    // Enum untuk status lahan
    enum StatusPenggunaan { Ditanami, MasaIstirahat, Panen }

    // Struct untuk menyimpan data satu bidang lahan
    struct DataLahan {
        string idLahan;           // ID unik lahan (contoh: "LAHAN-DIY-001")
        string namaPemilik;       // Nama pemilik lahan
        string lokasi;            // Desa/kecamatan
        StatusPenggunaan status;  // Status saat ini
        uint256 luasM2;           // Luas lahan dalam meter persegi
        uint256 tanggalUpdate;    // Timestamp update terakhir
        bool terdaftar;           // Apakah lahan sudah terdaftar
    }

    // Pemilik contract (pemerintah/admin)
    address public owner;

    // Mapping: id lahan → data lahan
    mapping(string => DataLahan) private dataLahan;

    // Mapping: alamat wallet → apakah petugas resmi
    mapping(address => bool) public petugasResmi;

    // Array untuk menyimpan semua ID lahan
    string[] public daftarIdLahan;

    // Events untuk transparansi
    event LahanTerdaftar(
        string indexed idLahan,
        string namaPemilik,
        string lokasi,
        uint256 timestamp
    );

    event StatusDiperbarui(
        string indexed idLahan,
        StatusPenggunaan statusLama,
        StatusPenggunaan statusBaru,
        address petugas,
        uint256 timestamp
    );

    event PetugasDitambahkan(address indexed petugas, uint256 timestamp);

    // Modifier: hanya owner
    modifier hanyaOwner() {
        require(msg.sender == owner, "Hanya owner yang bisa melakukan ini");
        _;
    }

    // Modifier: hanya petugas resmi atau owner
    modifier hanyaPetugas() {
        require(
            petugasResmi[msg.sender] || msg.sender == owner,
            "Hanya petugas resmi yang bisa memperbarui status"
        );
        _;
    }

    // Modifier: lahan harus sudah terdaftar
    modifier lahanHarusTerdaftar(string memory _idLahan) {
        require(dataLahan[_idLahan].terdaftar, "Lahan belum terdaftar");
        _;
    }

    // Constructor: owner = yang deploy contract
    constructor() {
        owner = msg.sender;
    }

    // Fungsi 1: Tambah petugas resmi (hanya owner)
    function tambahPetugas(address _petugas) public hanyaOwner {
        petugasResmi[_petugas] = true;
        emit PetugasDitambahkan(_petugas, block.timestamp);
    }

    // Fungsi 2: Daftarkan lahan baru
    function daftarkanLahan(
        string memory _idLahan,
        string memory _namaPemilik,
        string memory _lokasi,
        uint256 _luasM2,
        StatusPenggunaan _statusAwal
    ) public hanyaPetugas {
        require(!dataLahan[_idLahan].terdaftar, "Lahan sudah terdaftar");
        require(bytes(_idLahan).length > 0, "ID lahan tidak boleh kosong");
        require(_luasM2 > 0, "Luas lahan harus lebih dari 0");

        dataLahan[_idLahan] = DataLahan({
            idLahan: _idLahan,
            namaPemilik: _namaPemilik,
            lokasi: _lokasi,
            status: _statusAwal,
            luasM2: _luasM2,
            tanggalUpdate: block.timestamp,
            terdaftar: true
        });

        daftarIdLahan.push(_idLahan);

        emit LahanTerdaftar(_idLahan, _namaPemilik, _lokasi, block.timestamp);
    }

    // Fungsi 3: Perbarui status lahan
    function perbaruiStatus(
        string memory _idLahan,
        StatusPenggunaan _statusBaru
    ) public hanyaPetugas lahanHarusTerdaftar(_idLahan) {

        StatusPenggunaan statusLama = dataLahan[_idLahan].status;
        dataLahan[_idLahan].status = _statusBaru;
        dataLahan[_idLahan].tanggalUpdate = block.timestamp;

        emit StatusDiperbarui(
            _idLahan,
            statusLama,
            _statusBaru,
            msg.sender,
            block.timestamp
        );
    }

    // Fungsi 4: Lihat data lahan (publik, siapa saja bisa query)
    function lihatDataLahan(string memory _idLahan)
        public
        view
        lahanHarusTerdaftar(_idLahan)
        returns (
            string memory namaPemilik,
            string memory lokasi,
            string memory status,
            uint256 luasM2,
            uint256 tanggalUpdate
        )
    {
        DataLahan memory lahan = dataLahan[_idLahan];

        string memory namaStatus;
        if (lahan.status == StatusPenggunaan.Ditanami) {
            namaStatus = "Ditanami";
        } else if (lahan.status == StatusPenggunaan.MasaIstirahat) {
            namaStatus = "Masa Istirahat";
        } else {
            namaStatus = "Panen";
        }

        return (
            lahan.namaPemilik,
            lahan.lokasi,
            namaStatus,
            lahan.luasM2,
            lahan.tanggalUpdate
        );
    }

    // Fungsi 5: Hitung total lahan per status (untuk perencanaan wilayah)
    function totalLahanPerStatus(StatusPenggunaan _status)
        public
        view
        returns (uint256 jumlahBidang, uint256 totalLuasM2)
    {
        for (uint256 i = 0; i < daftarIdLahan.length; i++) {
            if (dataLahan[daftarIdLahan[i]].status == _status) {
                jumlahBidang++;
                totalLuasM2 += dataLahan[daftarIdLahan[i]].luasM2;
            }
        }
    }

    // Fungsi 6: Dapatkan total jumlah lahan terdaftar
    function totalLahanTerdaftar() public view returns (uint256) {
        return daftarIdLahan.length;
    }
}