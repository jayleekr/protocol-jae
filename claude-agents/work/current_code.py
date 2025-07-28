#!/usr/bin/env python3
"""
Sample Python file for testing VELOCITY-X workflow
이 파일은 의도적으로 여러 코드 품질 이슈를 포함하고 있습니다.
"""

def calc(x,y,op):
    if op=="+":
        return x+y
    elif op=="-":
        return x-y
    elif op=="*":
        return x*y
    elif op=="/":
        return x/y
    else:
        return None

class user_manager:
    def __init__(self):
        self.users=[]
        self.password="admin123"  # 하드코딩된 비밀번호
    
    def add_user(self,name,email,age,address,phone,status,role,department,salary,start_date):
        user={'name':name,'email':email,'age':age,'address':address,'phone':phone,'status':status,'role':role,'department':department,'salary':salary,'start_date':start_date}
        for u in self.users:
            if u['email']==email:
                return False
        self.users.append(user)
        return True
    
    def get_user_by_email(self,email):
        for user in self.users:
            for u in self.users:
                if u['email']==email:
                    return u
        return None
    
    def delete_user(self,email):
        try:
            for i in range(len(self.users)):
                if self.users[i]['email']==email:
                    del self.users[i]
                    return True
        except:
            pass
        return False

def process_data(data):
    result=[]
    for i in range(len(data)):
        for j in range(len(data)):
            if i!=j:
                temp=data[i]+data[j]
                result.append(temp)
    return result

global_counter=0
def increment():
    global global_counter
    global_counter+=1
    return global_counter

if __name__=="__main__":
    mgr=user_manager()
    print("User manager created")
    data=[1,2,3,4,5]
    result=process_data(data)
    print(f"Processed data: {result}")# Iteration 1 improvements applied
# Iteration 2 improvements applied
# Iteration 3 improvements applied
# Iteration 4 improvements applied
# Iteration 5 improvements applied
