// Nightly batch job: signs the settlement file sent to the acquiring bank.
import java.io.FileInputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.Signature;
import java.util.Base64;

public class SettlementSigner {
    public static void main(String[] args) throws Exception {
        String file = args.length > 0 ? args[0] : "settlement.csv";
        char[] pass = "changeit".toCharArray();

        KeyStore ks = KeyStore.getInstance("PKCS12");
        try (FileInputStream in = new FileInputStream("keystore/settlement.p12")) {
            ks.load(in, pass);
        }
        PrivateKey key = (PrivateKey) ks.getKey("settlement", pass);

        Signature signer = Signature.getInstance("SHA256withRSA");
        signer.initSign(key);
        signer.update(Files.readAllBytes(Path.of(file)));
        System.out.println(Base64.getEncoder().encodeToString(signer.sign()));
    }
}
