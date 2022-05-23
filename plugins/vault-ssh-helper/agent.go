
package helper

import (
	"fmt"
	"log"
	"net"
	"os"
	"strings"
	"bufio"  
	"encoding/json" 
	"io/ioutil"
	"database/sql" 

	"github.com/hashicorp/vault/api" 
	_ "github.com/go-sql-driver/mysql"	
)


//////////////////////////////////////////////////////
const (
	userFile string = "/etc/passwd"
	userJsonFile string = "/usr/local/share/tempuser/user.json"
)

type Users struct {
	Users []User `json:"users"`
}

type User struct {
	Name string `json:"name"`
	Directory string `json:"directory"`
	Group string `json:group`
	Shell string `json:shell`
}

// Read json file and return slice of byte.
func readUsers(f string) []byte {

	jsonFile, err := os.Open(f)

	if err != nil {
		fmt.Println(err)
	}
	defer jsonFile.Close()

	data, _ := ioutil.ReadAll(jsonFile)
	return data
}

// Read file /etc/passwd and return slice of users
func readEtcPasswd(f string) (list []string) {

	file, err := os.Open(f)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	r := bufio.NewScanner(file)

	for r.Scan() {
		lines := r.Text()
		parts := strings.Split(lines, ":")
		list = append(list, parts[0])
	}
	return list
}

// Check if user on the host
func check(s []string, u string) bool {
	for _, w := range s {
		if u == w {
			return true
		}
	}
	return false
}

func testActiveTempUser(testUser string) bool {
	conn,err := sql.Open("mysql", "linux:PASSWORD@tcp(172.31.37.26:3306)/master")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	rows,err := conn.Query("Select user from mysql.user;  ")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	
	isTempUser := false
	isExistUser := false
	isExpired := true

	//존재하는 유저인가?
	userList := readEtcPasswd(userFile)
	c := check(userList, testUser)
	if c == true {  
		isExistUser = true
	}

	//임시 유저인가?
	userJson := readUsers(userJsonFile)
	var users Users
	json.Unmarshal(userJson, &users)
	for i := range users.Users {
		if(users.Users[i].Name == testUser) {
			isTempUser = true
			break
		}
	}

	//현재 만료되지 않은 유저인가?
	for rows.Next() {
		var userName string
		rows.Scan(&userName)
		if(userName == testUser) {
			isExpired = false
			break
		}
	}

	// 존재하지 않는 유저인 경우 경우를 따지지 않음
	if(isExistUser) {
		fmt.Println("The user exists at etcpasswd :>", testUser)
	} else {
		fmt.Println("The user not exists at etcpasswd :>", testUser)
		return false
	}

	// 임시 유저가 아닌 경우 경우를 따지지 않음
	if(isTempUser) {
		fmt.Println("The user exists at user.json :>", testUser)
	} else {
		fmt.Println("The user not exists at user.json :>", testUser)
		return true
	}

	if(isExpired) {
		fmt.Println("The temporary user is expired :>", testUser)
		return false
	} else {
		fmt.Println("The temporary user is active :>", testUser)
	}

	return true
}
 




//////////////////////////////////////////////////////

// This allows the testing of the validateIPs function
var netInterfaceAddrs = net.InterfaceAddrs

// Structure representing the ssh-helper's verification request.
type SSHVerifyRequest struct {
	// Http client to communicate with Vault
	Client *api.Client

	// Mount point of SSH backend at Vault
	MountPoint string

	// This can be either an echo request message, which if set Vault will
	// respond with echo response message. OR, it can be the one-time-password
	// entered by the user at the prompt.
	OTP string

	// Structure containing configuration parameters of ssh-helper
	Config *api.SSHHelperConfig
}

// Reads the OTP from the prompt and sends the OTP to vault server. Server searches
// for an entry corresponding to the OTP. If there exists one, it responds with the
// IP address and username associated with it. The username returned should match the
// username for which authentication is requested (environment variable PAM_USER holds
// this value).
//
// IP address returned by vault should match the addresses of network interfaces or
// it should belong to the list of allowed CIDR blocks in the config file.
//
// This method is also used to verify if the communication between ssh-helper and Vault
// server can be established with the given configuration data. If OTP in the request
// matches the echo request message, then the echo response message is expected in
// the response, which indicates successful connection establishment.
func VerifyOTP(req *SSHVerifyRequest) error {
	// Validating the OTP from Vault server. The response from server can have
	// either the response message set OR username and IP set.
	resp, err := req.Client.SSHHelperWithMountPoint(req.MountPoint).Verify(req.OTP)
	if err != nil {
		return err
	}

	// If OTP sent was an echo request, look for echo response message in the
	// response and return
	if req.OTP == api.VerifyEchoRequest {
		if resp.Message == api.VerifyEchoResponse {
			log.Printf("[INFO] vault-ssh-helper verification successful!")
			return nil
		} else {
			return fmt.Errorf("invalid echo response")
		}
	}

	// PAM_USER represents the username for which authentication is being
	// requested. If the response from vault server mentions the username
	// associated with the OTP. It has to be a match.
	if resp.Username != os.Getenv("PAM_USER") {
		return fmt.Errorf("username mismatch")
	}

	// 임시 유저인 경우 DB 와 user.json 을 확인하여 만료된 유저인지 확인
	if testActiveTempUser(resp.Username) == false {
		return fmt.Errorf("[Error] Your account has expired.")
	}


	// The IP address to which the OTP is associated should be one among
	// the network interface addresses of the machine in which helper is
	// running. OR it should be present in allowed_cidr_list.
	if err := validateIP(resp.IP, req.Config.AllowedCidrList); err != nil {
		log.Printf("[INFO] failed to validate IP: %v", err)
		return err
	}

	// If AllowedRoles is `*`, regardless of the rolename returned by the
	// Vault server, authentication succeeds. If AllowedRoles is set to
	// specific role names, one of these should match the the role name in
	// the response for the authentication to succeed.
	if err := validateRoleName(resp.RoleName, req.Config.AllowedRoles); err != nil {
		log.Printf("[INFO] failed to validate role name: %v", err)
		return err
	}

	// Reaching here means that there were no problems. Returning nil will
	// gracefully terminate the binary and client will be authenticated to
	// establish the session.
	log.Printf("[INFO] %s@%s authenticated!", resp.Username, resp.IP)
	return nil
}

// Checks if the role name present in the verification response matches
// any of the allowed roles on the helper.
func validateRoleName(respRoleName, allowedRoles string) error {
	// Fail the validation when invalid allowed_roles is mentioned
	if allowedRoles == "" {
		return fmt.Errorf("missing allowed_roles")
	}

	// Fastpath to allow any role name
	if allowedRoles == "*" {
		return nil
	}

	respRoleName = strings.TrimSpace(respRoleName)
	if respRoleName == "" {
		return fmt.Errorf("missing role name in the verification response")
	}

	roles := strings.Split(allowedRoles, ",")
	log.Printf("roles: %s\n", roles)

	for _, role := range roles {
		// If an allowed role matches the role name in the response,
		// validation succeeds.
		if strings.TrimSpace(role) == respRoleName {
			return nil
		}
	}
	return fmt.Errorf("role name in the verification response not matching any of the allowed_roles")
}

// Finds out if given IP address belongs to the IP addresses associated with
// the network interfaces of the machine in which helper is running.
//
// If none of the interface addresses match the given IP, then it is search in
// the comma seperated list of CIDR blocks. This list is supplied as part of
// helper's configuration.
func validateIP(ipStr string, cidrList string) error {
	ip := net.ParseIP(ipStr)

	// Scanning network interfaces to find an address match
	interfaceAddrs, err := netInterfaceAddrs()
	if err != nil {
		return err
	}
	for _, addr := range interfaceAddrs {
		var base_addr net.IP
		switch ipAddr := addr.(type) {
		case *net.IPNet: //IPv4
			base_addr = ipAddr.IP
		case *net.IPAddr: //IPv6
			base_addr = ipAddr.IP
		}
		if (base_addr.String() == ip.String()) {
			return nil
		}
	}

	if len(cidrList) == 0 {
		return fmt.Errorf("IP did not match any of the network interface addresses. If this was expected, configure the 'allowed_cidr_list' option to allow the IP.")
	}

	// None of the network interface addresses matched the given IP.
	// Now, try to find a match with the given CIDR blocks.
	cidrs := strings.Split(cidrList, ",")
	for _, cidr := range cidrs {
		belongs, err := belongsToCIDR(ip, cidr)
		if err != nil {
			return err
		}
		if belongs {
			return nil
		}
	}

	return fmt.Errorf("invalid IP")
}

// Checks if the given CIDR block encompasses the given IP address.
func belongsToCIDR(ip net.IP, cidr string) (bool, error) {
	_, ipnet, err := net.ParseCIDR(cidr)
	if err != nil {
		return false, err
	}
	return ipnet.Contains(ip), nil
}
